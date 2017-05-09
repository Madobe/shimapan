require 'minitest/autorun'
require 'i18n'

require 'mock/manager/command_mock'
require 'model/role'
require 'model/setting'
require 'model/feed'

describe Mock::Manager::Commands do
  before :each do
    clear_models
    @manager = Mock::Manager::Commands.new
  end

  after :each do
    clear_models
  end

  def clear_models
    Role.delete_all
    Setting.delete_all
    Feed.delete_all
  end

  describe "!set" do
    it "saves correctly" do
      Role.new(server_id: 1, role_id: 1, user_id: 1).save
      assert_equal I18n.t("commands.set.saved", option: "mute_role", value: "1"), @manager.call(:set, *%w( mute_role 1 ))
    end

    it "rejects non-existent roles" do
      assert_equal I18n.t("commands.set.missing_resource"), @manager.call(:set, *%w( mute_role nonexistent ))
    end

    it "rejects non-existent channels" do
      assert_equal I18n.t("commands.set.missing_resource"), @manager.call(:set, *%w( absence_channel nonexistent ))
    end

    it "deletes if no value is given" do
      @manager.call(:set, *%w( absence_channel channel1 ))
      @manager.call(:set, "absence_channel")
      assert_empty Setting.where(server_id: 1, option: "absence_channel")
    end
  end

  describe "!applyforabsence" do
    it "requires a channel to be set" do
      assert_equal I18n.t("commands.applyforabsence.missing_channel"), @manager.call(:applyforabsence, *%w( because I can ))
    end
  end

  describe "!feed" do
    it "processes the modlog options correctly" do
      @manager.call(:feed, *%w( modlog -m1 ))
      refute_empty Feed.where(server_id: 1, allow: false, modifier: "m", target: 1)
    end

    it "processes the serverlog options correctly" do
      @manager.call(:feed, *%w( serverlog -n1 ))
      refute_empty Feed.where(server_id: 1, allow: false, modifier: "n", target: 1)
    end

    it "rejects incorrect options to modlog" do
      @manager.call(:feed, *%w( modlog -n1 ))
      assert_empty Feed.where(server_id: 1)
    end

    it "rejects incorrect options to serverlog" do
      @manager.call(:feed, *%w( serverlog -m1 ))
      assert_empty Feed.where(server_id: 1)
    end

    it "can actually flush the feeds" do
      @manager.call(:feed, *%w( modlog -m1 ))
      @manager.call(:feed, "flush")
      assert_empty Feed.where(server_id: 1)
    end

    it "displays the lists" do
      @manager.call(:feed, *%w( modlog -n1 ))
      refute_empty @manager.call(:feed, %w( list modlog ))
    end
  end

  describe "!role" do
    it "returns the correct ID" do
      assert_equal 3, @manager.call(:role, "role3")
    end
  end
end
