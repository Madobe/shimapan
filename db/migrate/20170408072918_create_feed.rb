class CreateFeed < ActiveRecord::Migration[5.0]
  def change
    create_table :feeds do |t|
      t.integer :server_id, null: false, limit: 8
      t.boolean :allow, null: false
      t.string :modifier, null: false
      t.integer :target, null: false, limit: 8
    end
  end
end
