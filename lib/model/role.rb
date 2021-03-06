# frozen_string_literal: true

require 'active_record'

class Role < ActiveRecord::Base
  belongs_to :member, primary_key: 'user_id', foreign_key: 'user_id'

  validates_presence_of :server_id, :user_id, :role_id
  validates_uniqueness_of :role_id, scope: [:server_id, :user_id]
end
