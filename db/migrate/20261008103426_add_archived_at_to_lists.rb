class AddArchivedAtToLists < ActiveRecord::Migration[8.1]
  def change
    add_column :lists, :archived_at, :datetime
    add_index :lists, :archived_at
  end
end
