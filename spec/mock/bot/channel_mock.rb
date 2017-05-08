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
end
