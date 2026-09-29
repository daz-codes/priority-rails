class AddLastActiveAtToSessions < ActiveRecord::Migration[8.1]
  def up
    add_column :sessions, :last_active_at, :datetime
    # Start the inactivity clock now so nobody is signed out by this deploy
    execute "UPDATE sessions SET last_active_at = CURRENT_TIMESTAMP"
    change_column_null :sessions, :last_active_at, false
    add_index :sessions, :last_active_at
  end

  def down
    remove_column :sessions, :last_active_at
  end
end
