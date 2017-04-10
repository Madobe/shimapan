class CreateMessage < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.integer :server_id, null: false, limit: 8
      t.integer :channel_id, null: false, limit: 8
      t.integer :user_id, null: false, limit: 8
      t.integer :message_id, null: false, limit: 8
      t.string :username, null: false
      t.text :content
      t.text :attachments
    end
  end
end
