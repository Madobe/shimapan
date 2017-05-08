require 'yaml'
require 'manager/base'
require 'manager/log'
require 'mock/command_bot'

module Mock
  module Manager
    class Logs < ::Manager::Logs
      def initialize
        ::Manager::Base.start(false)
        ::Manager::Commands.class_variable_set(:@@bot, Mock::CommandBot.new)
      end

      def write_message(event, message, log = "serverlog")
        "write_message called"
      end
    end
  end
end
