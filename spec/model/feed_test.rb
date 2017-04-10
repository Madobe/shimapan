require 'minitest/autorun'
require 'model/feed'

describe Feed do
  before :each do
    Feed.delete_all
    @feed = Feed.new
    @feed2 = Feed.new
  end

  after :each do
    Feed.delete_all
  end

  it "requires a server_id" do
    @feed.valid?
    assert_includes @feed.errors[:server_id], I18n.t("errors.messages.blank")
  end

  it "requires an allow boolean" do
    @feed.valid?
    assert_includes @feed.errors[:allow], I18n.t("errors.messages.inclusion")
  end

  it "requires a modifier" do
    @feed.valid?
    assert_includes @feed.errors[:modifier], I18n.t("errors.messages.blank")
  end

  it "requires a target" do
    @feed.valid?
    assert_includes @feed.errors[:target], I18n.t("errors.messages.blank")
  end

  it "requires target to be unique if all other attributes are the same" do
    @feed.server_id = 1
    @feed.allow = true
    @feed.modifier = "m"
    @feed.target = 1
    assert_equal @feed.save, true

    @feed2.server_id = 1
    @feed2.allow = true
    @feed2.modifier = "m"
    @feed2.target = 1
    assert_equal @feed2.save, false

    @feed2.target = 2
    assert_equal @feed2.save, true
  end
end
