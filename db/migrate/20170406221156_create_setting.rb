class CreateSetting < ActiveRecord::Migration[5.0]
  def change
    create_table :settings do |t|
      t.integer :server_id, null: false, limit: 8
      t.string :option, null: false
      t.string :value, null: false
    end
  end
end
