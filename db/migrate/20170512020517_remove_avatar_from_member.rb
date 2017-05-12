class RemoveAvatarFromMember < ActiveRecord::Migration[5.0]
  def change
    remove_column :members, :avatar, :string
  end
end
