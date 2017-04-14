require 'active_record'

class Message < ActiveRecord::Base
  validates_presence_of :server_id, :channel_id, :user_id, :message_id, :username, :content
  validates_uniqueness_of :message_id, scope: :server_id

  def to_printable
    output = content
    output << "\n\n" << attachments unless attachments.empty?
    output
  end
end
