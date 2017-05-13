# frozen_string_literal: true

require 'active_record'

class User < ActiveRecord::Base
  validates_presence_of :user_id, :username
  validates_uniqueness_of :user_id
end
