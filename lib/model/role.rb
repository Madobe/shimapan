require 'active_record'

class Role < ActiveRecord::Base
  validates_presence_of :server_id, :user_id, :role_id
end
