require 'yaml'
require 'discordrb'
require 'i18n'
require 'active_record'
require_relative '../module/utilities'

# Write and delete PID files as necessary
BEGIN { File.write('/var/run/shimapan/shimapan.pid', $$) }
END { File.delete('/var/run/shimapan/shimapan.pid') if File.exists?('/var/run/shimapan/shimapan.pid') }

# A derivative of the String class to make checking environment easy and clean.
class Environment < String
  def initialize(environment = "test")
    if %w( development production test ).include? environment
      super(environment)
    else
      super("test")
    end
  end

  def development?; self == "development"; end
  def production?; self == "production"; end
  def test?; self == "test"; end
end

module Manager
  class Base
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

    def self.sync
      @@bot.sync
    end

    def root; @@root; end
    def env; @@env; end
    def bot; @@bot; end

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

    # Find the member indicated by the input string. This may be their display name or username.
    # @param string [String] The string to search for.
    def find_member(event, string)
      regex = Regexp.new(string)
      server = resolve_server(event)
      server.members.select { |member| member.display_name =~ regex || member.username =~ regex }
    end

    def debug(message)
      Manager::Base.debug(message)
    end

    private

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

    def self.set_root
      @@root ||= File.expand_path(File.dirname(__FILE__)).split('/')[0..-2].join('/');
      debug "Root set to `#{@@root}`."
    end

    def self.set_env
      @@env ||= Environment.new(ENV['ENV']);
      debug "Environment set to `#{@@env}`. ENV['ENV'] was `#{ENV['ENV']}`."
    end

    def self.load_i18n
      load_path = File.join(@@root, "locales", "*.yml")
      I18n.load_path.concat(Dir[load_path])
      self.debug "I18n.load_path had #{load_path} added."
      I18n.backend.load_translations
    end

    def self.debug(message)
      Dir.mkdir(File.join(@@root, "data")) unless File.exists?(File.join(@@root, "data"))
      File.open(File.join(@@root, "data", "bot.log"), "a") do |f|
        f.write(message.timestamp(false))
        f.write("\n")
      end
    end
  end
end
