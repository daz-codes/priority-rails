class AddUniqueIndexToPendingInvitations < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE pending_invitations SET email = LOWER(TRIM(email))"
    execute <<~SQL
      DELETE FROM pending_invitations
      WHERE id NOT IN (SELECT MIN(id) FROM pending_invitations GROUP BY list_id, email)
    SQL

    add_index :pending_invitations, [ :list_id, :email ], unique: true
  end

  def down
    remove_index :pending_invitations, [ :list_id, :email ]
  end
end
