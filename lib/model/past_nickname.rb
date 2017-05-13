# frozen_string_literal: true

require 'active_record'

class PastNickname < ActiveRecord::Base
  validates_presence_of :user_id, :nickname
end
