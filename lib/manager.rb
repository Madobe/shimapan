require 'yaml'

require_relative 'commands'
require_relative 'logs'

class Manager
  # Instantiates this container. Should only be called from init.rb.
  # @param bot [CommandBot] An instance of the Discordrb CommandBot.
  def initialize(bot)
    @@bot = bot
    @@coms_manager = CommandsManager.new
    @@logs_manager = LogsManager.new
  end

  # Allows access of our bot variable without having to pass it as an argument.
  def self.bot
    @@bot
  end
end
