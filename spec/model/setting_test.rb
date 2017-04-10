require 'minitest/autorun'
require 'model/setting'

describe Setting do
  before :each do
    Setting.delete_all
    @setting = Setting.new
  end

  after :each do
    Setting.delete_all
  end

  it "requires a server_id" do
    @setting.valid?
    assert_includes @setting.errors[:server_id], "can't be blank"
  end

  it "requires a option" do
    @setting.valid?
    assert_includes @setting.errors[:option], "can't be blank"
  end

  it "requires a value" do
    @setting.valid?
    assert_includes @setting.errors[:value], "can't be blank"
  end
end
