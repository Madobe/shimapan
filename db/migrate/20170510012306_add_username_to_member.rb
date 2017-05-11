class AddUsernameToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :username, :string, null: false
  end
end
