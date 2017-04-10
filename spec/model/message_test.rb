require 'minitest/autorun'
require 'model/message'

describe Message do
  before :each do
    Message.delete_all
    @message = Message.new
    @message2 = Message.new
  end

  after :each do
    Message.delete_all
  end

  it "requires a server_id" do
    @message.valid?
    assert_includes @message.errors[:server_id], "can't be blank"
  end

  it "requires a channel_id" do
    @message.valid?
    assert_includes @message.errors[:channel_id], "can't be blank"
  end

  it "requires a user_id" do
    @message.valid?
    assert_includes @message.errors[:user_id], "can't be blank"
  end

  it "requires a message_id" do
    @message.valid?
    assert_includes @message.errors[:message_id], "can't be blank"
  end

  it "requires a username" do
    @message.valid?
    assert_includes @message.errors[:username], "can't be blank"
  end

  it "requires a content" do
    @message.valid?
    assert_includes @message.errors[:content], "can't be blank"
  end

  it "requires a unique server_id + message_id combination" do
    @message.server_id = 1
    @message.channel_id = 1
    @message.user_id = 1
    @message.message_id = 1
    @message.username = "username"
    @message.content = "content"
    assert_equal @message.save, true

    @message2.server_id = 1
    @message2.channel_id = 2
    @message2.user_id = 2
    @message2.message_id = 1
    @message2.username = "username2"
    @message2.content = "content2"
    assert_equal @message2.save, false
  end
end
