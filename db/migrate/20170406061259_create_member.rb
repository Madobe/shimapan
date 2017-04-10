class CreateMember < ActiveRecord::Migration[5.0]
  def change
    create_table :members do |t|
      t.integer :server_id, null: false, limit: 8
      t.integer :user_id, null: false, limit: 8
      t.string :display_name, null: false
      t.string :avatar
    end
  end
end
