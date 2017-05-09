module Mock
  class Member
    attr_reader :id, :display_name, :avatar

    def initialize(id, owner = true)
      @id = id
      @display_name = "member#{id}"
      @avatar = "avatar#{id}"
      @owner = owner
    end

    def owner?
      owner
    end
  end
end
