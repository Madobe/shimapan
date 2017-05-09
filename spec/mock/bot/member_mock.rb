module Mock
  class Member
    attr_reader :id, :display_name, :avatar

    def initialize(id)
      @id = id
      @display_name = "member#{id}"
      @avatar = "avatar#{id}"
    end

    def owner?
      true
    end
  end
end
