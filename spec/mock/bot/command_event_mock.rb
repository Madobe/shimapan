module Mock
  class CommandEvent
    attr_reader :server

    def initialize
      @server = Server.new(1)
    end

    def respond(message)
      message
    end
  end
end
