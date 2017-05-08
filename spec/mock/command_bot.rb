require 'mock/bot/server_mock'
require 'mock/bot/role_mock'
require 'mock/bot/channel_mock'
require 'mock/bot/command_mock'
require 'mock/bot/command_event_mock'
require 'mock/bot/log_events_mock'

module Mock
  class CommandBot
    def initialize
      @commands = {}
    end

    def command(name, *attributes, &block)
      @commands[name] = Command.new(name, attributes, block)
    end

    def call(command, args)
      @commands[command].call(CommandEvent.new, args)
    end

    def sync; end

    def member_join(&block)
      event = MemberJoinEvent.new
      block.call(event)
    end
  end
end
