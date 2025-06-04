class RemoveUserIdFromLists < ActiveRecord::Migration[8.0]
  def change
    remove_reference :lists, :user, null: false, foreign_key: true
  end
end
