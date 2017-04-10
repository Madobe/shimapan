module Mock
  class Channel
    attr_reader :id, :name

    def initialize(id)
      @id = id
      @name = "channel#{id}"
    end

    def send_message(message)
      "message received"
    end
  end

  class Role
    attr_reader :id, :name

    def initialize(id)
      @id = id
      @name = "role#{id}"
    end
  end

  class Server
    attr_reader :id, :channels, :text_channels, :roles

    def initialize(id)
      @id = id
      @channels = [] << Channel.new(1) << Channel.new(2) << Channel.new(3)
      @text_channels = @channels
      @roles = [] << Role.new(1) << Role.new(2) << Role.new(3)
    end
  end

  class Command
    def initialize(name, attributes, block)
      @name = name
      @attributes = attributes
      @block = block
    end

    def call(event, args)
      @block.call(event, *args)
    rescue LocalJumpError
      nil
    end
  end

  class CommandEvent
    attr_reader :server

    def initialize
      @server = Server.new(1)
    end

    def respond(message)
      message
    end
  end

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
  end
end
