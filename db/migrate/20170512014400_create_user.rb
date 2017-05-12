class CreateUser < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.integer :user_id, null: false, limit: 8
      t.string :username, null: false
      t.string :avatar

      t.timestamps
    end
  end
end
