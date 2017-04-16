require 'active_record'

class Role < ActiveRecord::Base
  validates_presence_of :server_id, :user_id, :role_id
  validates_uniqueness_of :role_id, scope: [:server_id, :user_id]
end
