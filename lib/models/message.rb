require_relative '../datatype/dbtable'

class Message < DBTable
  attr_accessor :server_id, :channel_id, :user_id, :message_id, :username, :content, :attachments
end
