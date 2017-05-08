require 'active_record'

class Moderator < ActiveRecord::Base
  validates_presence_of :server_id, :user_id
  validates_uniqueness_of :user_id, scope: :server_id
end
