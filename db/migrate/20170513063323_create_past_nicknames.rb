class CreatePastNicknames < ActiveRecord::Migration[5.0]
  def change
    create_table :past_nicknames do |t|
      t.integer :user_id, null: false, limit: 8
      t.string :nickname, null: false
      t.datetime :created_at, null: false
    end
  end
end
