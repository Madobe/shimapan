require 'mock/bot/member_mock'

module Mock
  class CommandEvent
    attr_reader :server, :author

    def initialize
      @server = Server.new(1)
      @author = Member.new(1)
    end

    def respond(message)
      message
    end
  end
end
