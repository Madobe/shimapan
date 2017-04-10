require 'minitest/autorun'
require 'model/custom_command'

describe CustomCommand do
  before :each do
    CustomCommand.delete_all
    @command = CustomCommand.new
    @command2 = CustomCommand.new
  end

  after :each do
    CustomCommand.delete_all
  end

  it "requires a server_id" do
    @command.valid?
    assert_includes @command.errors[:server_id], "can't be blank"
  end

  it "requires a trigger" do
    @command.valid?
    assert_includes @command.errors[:trigger], "can't be blank"
  end

  it "requires output" do
    @command.valid?
    assert_includes @command.errors[:output], "can't be blank"
  end

  it "requires a unique server_id + trigger combination" do
    @command.server_id = 1
    @command.trigger = "trigger"
    @command.output = "output"
    assert_equal @command.save, true

    @command2.server_id = 1
    @command2.trigger = "trigger"
    @command2.output = "output2"
    assert_equal @command2.save, false
  end
end
