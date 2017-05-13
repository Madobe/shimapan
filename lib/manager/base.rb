# frozen_string_literal: true

require 'yaml'
require 'discordrb'
require 'i18n'
require 'active_record'
require_relative '../module/utilities'

# Write and delete PID files as necessary
BEGIN { File.write('/var/run/shimapan/shimapan.pid', $$) unless ENV['ENV'] == "test" }
END { File.delete('/var/run/shimapan/shimapan.pid') if File.exist?('/var/run/shimapan/shimapan.pid') && ENV['ENV'] != "test" }

# A derivative of the String class to make checking environment easy and clean.
class Environment < String
  # Defaults to test if not given an input or given an invalid input.
  # @option environment [String] The environment we're deploying under. Has 3 possible values.
  def initialize(environment = "test")
    if %w( development production test ).include? environment
      super(environment)
    else
      super("test")
    end
  end

  # Just some commands to make it more readable if we check the environment.
  def development?; self == "development"; end
  def production?; self == "production"; end
  def test?; self == "test"; end
end

# The Manager module is just namespacing.
module Manager
  # Basically just a class that houses the bot and starts everything that the other managers will
  # need.
  class Base
    # Load up all the starting values and initialize the components the bot relies on.
    # @option start_bot [Boolean] Whether or not to start the bot. This is used to allow the
    # execution of this command for testing but not lock the execution by booting the bot for real
    # too.
    def self.start(start_bot = true)
      self.set_root
      self.set_env
      self.initialize_database
      self.load_i18n
      if start_bot
        connection_config = YAML.load_file(File.join(@@root, "config", "connect.yml"))
        @@bot ||= Discordrb::Commands::CommandBot.new token: connection_config['token'], client_id: connection_config['client_id'], prefix: '!', help_command: false, ignore_bots: true
        @@bot.ready { |event| @@bot.game = "!help" }
        @@bot.run(true)
      end
    end

    # Syncs the bot to stop asynchronous execution. Used to allow the other managers to run too
    # (because this one must run first).
    def self.sync
      @@bot.sync
    end

    protected

    # Gets the server object from an event object.
    # @param event [Event] An Event instance.
    def resolve_server(event)
      if event.respond_to? :server
        event.server
      else
        event.channel.server
      end
    end

    # Find members indicated by the input string. This may be their display name or username or
    # it'll just be the mention in the Event object.
    # @param event [Event] May be a CommandEvent or some event from the Logs.
    # @param string [String] The string to search for.
    def find_members(event, string)
      if event.respond_to?(:message) && event.message.mentions.empty? && !string
        event.respond I18n.t("commands.common.no_user_matched")
        nil
      elsif event.respond_to?(:message) && !event.message.mentions.empty?
        event.message.mentions
      else
        regex = Regexp.new(string)
        server = resolve_server(event)
        server.members.select { |member|
          member.respond_to?(:display_name) && member.display_name =~ regex ||
          member.respond_to?(:username) && member.username =~ regex ||
          member.respond_to?(:distinct) && member.distinct =~ regex
        }
      end
    rescue NoMethodError
      nil
    end

    # Find a single member. Just adds more checks on top of find_member.
    # @param event [Event] May be a CommandEvent or some event from the Logs.
    # @param string [String] The string to search for.
    # @option check_int [Boolean] Whether or not to check if the string is actually just all
    # numbers.
    def find_one_member(event, string, check_int = false)
      return string if check_int && string == string.gsub(/\D/, '')
      return nil unless (event.respond_to?(:message) && !event.message.mentions.empty?) || (!string.nil? && !string.empty?)
      members = self.find_members(event, string)
      if members && string && members.size > 1
        member = members.find { |member| member.display_name == string || member.username == string || member.distinct == string}
        if member
          return member
        else
          event.respond I18n.t("commands.common.too_many_matches", {
            matches: members.map(&:distinct).map { |identifier| "-#{identifier}" }.join("\n")
          })
          nil
        end
      else
        members.first
      end
    end

    # Logs a message to the bot's log file in lib/data/bot.log. Calls the private method.
    # @param message [String] What to write to the log file. Timestamp is appended at the time of
    # writing.
    def debug(message)
      Manager::Base.debug(message)
    end

    private

    # Reads the configurations and initializes the database connection for ActiveRecord objects.
    def self.initialize_database
      config = YAML.load_file(File.join(@@root, "config", "database.yml"))[@@env]
      ActiveRecord::Base.establish_connection(
        adapter:  'mysql2',
        host:     config['host'],
        username: config['username'],
        password: config['password'],
        database: config['database']
      )
      debug "Establishing connection to `#{config['database']}` under `#{@@env}` environment."
    end

    # Set the root directory to be lib/
    def self.set_root
      @@root ||= File.expand_path(File.dirname(__FILE__)).split('/')[0..-2].join('/');
      debug "Root set to `#{@@root}`."
    end

    # Set the environment variable based on ENV['ENV']. It's easier to access and sometimes
    # disappears otherwise.
    def self.set_env
      @@env ||= Environment.new(ENV['ENV']);
      debug "Environment set to `#{@@env}`. ENV['ENV'] was `#{ENV['ENV']}`."
    end

    # Load up the localization files for I18n.
    def self.load_i18n
      load_path = File.join(@@root, "locales", "*.yml")
      I18n.load_path.concat(Dir[load_path])
      self.debug "I18n.load_path had #{load_path} added."
      I18n.backend.load_translations
    end

    # Logs a message to the bot's log file in lib/data/bot.log.
    # @param message [String] What to write to the log file. Timestamp is appended at the time of
    # writing.
    def self.debug(message)
      return
#      Dir.mkdir(File.join(@@root, "data")) unless File.exist?(File.join(@@root, "data"))
#      File.open(File.join(@@root, "data", "bot.log"), "a") do |f|
#        f.write(message.timestamp(false))
#        f.write("\n")
#      end
    end
  end
end
