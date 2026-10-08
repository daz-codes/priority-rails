class MakeFirstCategoryTheDefault < ActiveRecord::Migration[8.1]
  # The first category (by position) is now the default for new tasks. Move each list's starred
  # default to the top first, so nobody's default changes.
  def up
    execute <<~SQL
      UPDATE categories SET position = position + 1
      WHERE EXISTS (
        SELECT 1 FROM lists
        WHERE lists.id = categories.list_id
          AND lists.default_category_id IS NOT NULL
          AND lists.default_category_id != categories.id
          AND categories.position < (SELECT d.position FROM categories AS d WHERE d.id = lists.default_category_id)
      )
    SQL
    execute <<~SQL
      UPDATE categories SET position = 1
      WHERE id IN (SELECT default_category_id FROM lists WHERE default_category_id IS NOT NULL)
    SQL
    remove_reference :lists, :default_category, foreign_key: { to_table: :categories, on_delete: :nullify }
  end

  def down
    add_reference :lists, :default_category, foreign_key: { to_table: :categories, on_delete: :nullify }
    execute <<~SQL
      UPDATE lists SET default_category_id = (
        SELECT id FROM categories WHERE categories.list_id = lists.id ORDER BY position, id LIMIT 1
      )
    SQL
  end
end
