require 'active_record'

class Message < ActiveRecord::Base
  validates_presence_of :server_id, :channel_id, :user_id, :message_id, :username, :content
  validates_uniqueness_of :message_id, scope: :server_id
end
