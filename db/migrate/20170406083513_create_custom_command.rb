class CreateCustomCommand < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_commands do |t|
      t.integer :server_id, null: false, limit: 8
      t.string :trigger, null: false
      t.string :output, null: false
    end
  end
end
