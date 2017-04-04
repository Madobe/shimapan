require 'yaml'

require_relative 'commands'
require_relative 'logs'
require_relative 'database'

class Manager
  # Instantiates this container. Should only be called from init.rb.
  # @param bot [CommandBot] An instance of the Discordrb CommandBot.
  def initialize(bot)
    @@bot = bot
    @@db_manager = Database.new
    @@coms_manager = CommandsManager.new
    @@logs_manager = LogsManager.new
  end

  # Allows access of our bot variable without having to pass it as an argument.
  def self.bot
    @@bot
  end

  # Allows access of our db_manager variable without having to pass it as an argument.
  def self.db
    @@db_manager
  end

  def self.root
    ENV['SHIMA_ROOT'] || File.expand_path(File.dirname(__FILE__))
  end

  class Environment < String
    def development?
      self == "development"
    end

    def production?
      self == "production"
    end

    def test?
      self == "test"
    end
  end

  def self.env
    @env ||= Environment.new(ENV['ENVIRONMENT'] || "test")
  end
end
