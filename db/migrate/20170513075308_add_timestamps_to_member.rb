class AddTimestampsToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :created_at, :datetime
    add_column :members, :updated_at, :datetime
  end
end
