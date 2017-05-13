# frozen_string_literal: true

require 'active_record'

class Setting < ActiveRecord::Base
  validates_presence_of :server_id, :option, :value
end
