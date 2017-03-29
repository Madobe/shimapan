require_relative '../datatype/dbtable'

class Member < DBTable
  attr_accessor :server_id, :user_id, :display_name, :avatar
  acts_as_foreign_key :roles, :user_id
end
