require 'active_record'

class CustomCommand < ActiveRecord::Base
  validates_presence_of :server_id, :trigger, :output
  validates_uniqueness_of :trigger, scope: :server_id
end
