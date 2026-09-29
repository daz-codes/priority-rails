class AddOwnerToLists < ActiveRecord::Migration[8.1]
  def up
    add_reference :lists, :owner, foreign_key: { to_table: :users, on_delete: :nullify }

    # The creator was never recorded, so treat the longest-standing member as owner
    execute <<~SQL
      UPDATE lists
      SET owner_id = (SELECT MIN(user_id) FROM lists_users WHERE lists_users.list_id = lists.id)
    SQL
  end

  def down
    remove_reference :lists, :owner, foreign_key: { to_table: :users }
  end
end
