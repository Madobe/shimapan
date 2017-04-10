require 'active_record'

class Feed < ActiveRecord::Base
  validates_presence_of :server_id, :modifier, :target
  validates_uniqueness_of :target, scope: [:server_id, :allow, :modifier]
  validates_inclusion_of :allow, in: [true, false]
end
