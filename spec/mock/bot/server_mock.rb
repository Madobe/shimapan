require 'mock/bot/channel_mock'
require 'mock/bot/member_mock'
require 'mock/bot/role_mock'

module Mock
  class Server
    attr_reader :id, :channels, :text_channels, :members, :roles

    def initialize(id)
      @id = id
      @channels = [] << Channel.new(1) << Channel.new(2) << Channel.new(3)
      @text_channels = @channels
      @members = [] << Member.new(1) << Member.new(2) << Member.new(3)
      @roles = [] << Role.new(1) << Role.new(2) << Role.new(3)
    end
  end
end
