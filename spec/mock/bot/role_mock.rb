module Mock
  class Role
    attr_reader :id, :name

    def initialize(id)
      @id = id
      @name = "role#{id}"
    end
  end
end
