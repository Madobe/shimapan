require 'minitest/autorun'
require 'model/role'

describe Role do
  before :each do
    Role.delete_all
    @role = Role.new
  end

  after :each do
    Role.delete_all
  end

  it "requires a server_id" do
    @role.valid?
    assert_includes @role.errors[:server_id], "can't be blank"
  end

  it "requires a user_id" do
    @role.valid?
    assert_includes @role.errors[:user_id], "can't be blank"
  end

  it "requires a role_id" do
    @role.valid?
    assert_includes @role.errors[:role_id], "can't be blank"
  end
end
