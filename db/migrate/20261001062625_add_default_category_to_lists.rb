class AddDefaultCategoryToLists < ActiveRecord::Migration[8.1]
  def up
    add_reference :lists, :default_category, foreign_key: { to_table: :categories, on_delete: :nullify }

    # Keep what each list effectively used before: a category named "Work", otherwise the first one
    execute <<~SQL
      UPDATE lists SET default_category_id = COALESCE(
        (SELECT id FROM categories WHERE categories.list_id = lists.id AND categories.name = 'Work' LIMIT 1),
        (SELECT MIN(id) FROM categories WHERE categories.list_id = lists.id)
      )
    SQL
  end

  def down
    remove_reference :lists, :default_category, foreign_key: { to_table: :categories }
  end
end
