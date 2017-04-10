require 'yaml'
require 'manager/base'
require 'manager/command'
require 'mock/command_bot'

module Mock
  module Manager
    class Commands < ::Manager::Commands
      def initialize
        ::Manager::Base.start(false)
        ::Manager::Commands.class_variable_set(:@@bot, Mock::CommandBot.new)
        add_base_commands
        add_custom_commands
      end

      def call(command, *args)
        @@bot.call(command, args)
      end
    end
  end
end
