require 'minitest/autorun'
require 'model/moderator'

describe Moderator do
  before :each do
    Moderator.delete_all
    @mod = Moderator.new
    @mod2 = Moderator.new
  end

  after :each do
    Moderator.delete_all
  end

  it "requires a server_id" do
    @mod.valid?
    assert_includes @mod.errors[:server_id], "can't be blank"
  end

  it "requires a user_id" do
    @mod.valid?
    assert_includes @mod.errors[:user_id], "can't be blank"
  end

  it "requires a unique user_id per server_id" do
    @mod.server_id = 1
    @mod.user_id   = 1
    assert_equal true, @mod.save

    @mod2.server_id = 1
    @mod2.user_id   = 1
    assert_equal false, @mod2.save
  end
end
