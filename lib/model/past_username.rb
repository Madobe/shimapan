# frozen_string_literal: true

require 'active_record'

class PastUsername < ActiveRecord::Base
  validates_presence_of :user_id, :username
end
