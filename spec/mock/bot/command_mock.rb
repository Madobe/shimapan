module Mock
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
end
