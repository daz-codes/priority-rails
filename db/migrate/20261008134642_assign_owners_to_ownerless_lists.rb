class AssignOwnersToOwnerlessLists < ActiveRecord::Migration[8.1]
  # Lists without an owner can't be archived, deleted or managed by anyone (and fail validation when
  # saved). Give them the longest-standing member, as the original ownership migration did.
  def up
    execute <<~SQL
      UPDATE lists
      SET owner_id = (SELECT MIN(user_id) FROM lists_users WHERE lists_users.list_id = lists.id)
      WHERE owner_id IS NULL
    SQL
  end

  def down
    # Nothing to undo: which lists had no owner isn't recorded
  end
end
