require 'active_record'

class Member < ActiveRecord::Base
  has_many :roles, primary_key: 'user_id'.freeze, foreign_key: 'user_id'.freeze

  validates_presence_of :server_id, :user_id, :display_name
  validates_uniqueness_of :user_id, scope: :server_id
end
