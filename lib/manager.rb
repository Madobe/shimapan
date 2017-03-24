require 'yaml'

require_relative 'command'

class Manager
  # Instantiates this container. Should only be called from init.rb.
  # @param bot [CommandBot] An instance of the Discordrb CommandBot.
  def initialize(bot)
    @@help_messages = YAML.load_file('config/help_messages.yaml')

    @@bot = bot
    @@coms_manager = CommandsManager.new
    #@@logs_manager = 
  end

  # Allows access of our bot variable without having to pass it as an argument.
  def self.bot
    @@bot
  end
end
