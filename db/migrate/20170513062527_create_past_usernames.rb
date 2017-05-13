class CreatePastUsernames < ActiveRecord::Migration[5.0]
  def change
    create_table :past_usernames do |t|
      t.integer :user_id, null: false, limit: 8
      t.string :username, null: false
      t.datetime :created_at, null: false
    end
  end
end
