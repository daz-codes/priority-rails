class AddPositionToCategories < ActiveRecord::Migration[8.1]
  def up
    add_column :categories, :position, :integer
    # Keep each list's current order (creation order)
    execute <<~SQL
      UPDATE categories SET position = (
        SELECT COUNT(*) FROM categories AS earlier
        WHERE earlier.list_id = categories.list_id AND earlier.id <= categories.id
      )
    SQL
    change_column_null :categories, :position, false
    add_index :categories, [ :list_id, :position ]
  end

  def down
    remove_column :categories, :position
  end
end
