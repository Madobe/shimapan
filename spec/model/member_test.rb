require 'minitest/autorun'
require 'model/member'

describe Member do
  before :each do
    Member.delete_all
    @member = Member.new
    @member2 = Member.new
  end

  after :each do
    Member.delete_all
  end

  it "requires a server_id" do
    @member.valid?
    assert_includes @member.errors[:server_id], "can't be blank"
  end

  it "requires a user_id" do
    @member.valid?
    assert_includes @member.errors[:user_id], "can't be blank"
  end

  it "requires a display_name" do
    @member.valid?
    assert_includes @member.errors[:display_name], "can't be blank"
  end

  it "requires a unique server_id + user_id combination" do
    @member.server_id = 1
    @member.user_id = 1
    @member.display_name = "Member"
    assert_equal @member.save, true

    @member2.server_id = 1
    @member2.user_id = 1
    @member2.display_name = "Member"
    assert_equal @member2.save, false
  end
end
