class CreateRole < ActiveRecord::Migration[5.0]
  def change
    create_table :roles do |t|
      t.integer :server_id, null: false, limit: 8
      t.integer :user_id, null: false, limit: 8
      t.integer :role_id, null: false, limit: 8
    end
  end
end
