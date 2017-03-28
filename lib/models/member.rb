require_relative '../datatype/dbtable'

class Member < DBTable
  attr_accessor :server_id, :user_id, :display_name, :avatar
end
