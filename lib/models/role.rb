require_relative '../datatype/dbtable'

class Role < DBTable
  attr_accessor :server_id, :user_id, :role_id
end
