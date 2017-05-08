require 'minitest/autorun'
require 'i18n'

require 'mock/manager/log_mock'

describe Mock::Manager::Logs do
  before :each do
    @manager = Mock::Manager::Logs.new
  end

  describe "member_join" do
    it "saves the member's info to the database" do
    end
  end

  describe "member_leave" do
    it "deletes the member's info from the database" do
    end
    
    it "deletes the member's associated roles from the database" do
    end
  end

  describe "member_update" do
    it "detects nickname changes" do
    end

    it "detects role changes" do
    end
  end

  describe "message" do
    it "saves new messages" do
    end
  end

  describe "message_edit" do
    describe "permissions" do
      it "denies from blanket settings" do
      end

      it "denies from user-specific settings" do
      end

      it "allows from user-specific settings" do
      end

      it "allows by default" do
      end
    end
  end

  describe "message_delete" do
  end

  describe "user_ban" do
  end

  describe "user_unban" do
  end
end
