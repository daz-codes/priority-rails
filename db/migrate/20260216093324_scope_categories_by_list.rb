class ScopeCategoriesByList < ActiveRecord::Migration[8.0]
  def up
    # 1. Add list_id to categories and drop the old unique index on name
    add_column :categories, :list_id, :integer
    remove_index :categories, :name

    # 2. For each list_category join, create a dedicated category copy for that list
    execute <<~SQL
      INSERT INTO categories (name, color, list_id, created_at, updated_at)
      SELECT c.name, c.color, lc.list_id, datetime('now'), datetime('now')
      FROM list_categories lc
      JOIN categories c ON c.id = lc.category_id
      WHERE c.list_id IS NULL
    SQL

    # 3. Re-point tasks to their list's own category copy
    execute <<~SQL
      UPDATE tasks
      SET category_id = (
        SELECT new_c.id
        FROM categories new_c
        WHERE new_c.list_id = tasks.list_id
          AND new_c.name = (SELECT old_c.name FROM categories old_c WHERE old_c.id = tasks.category_id)
      )
      WHERE category_id IS NOT NULL
    SQL

    # 4. Drop the join table (must happen before deleting old categories due to FK)
    drop_table :list_categories

    # 5. Delete the old shared (list_id IS NULL) categories
    execute "DELETE FROM categories WHERE list_id IS NULL"

    # 6. Add unique index scoped to list
    add_index :categories, [ :list_id, :name ], unique: true

    # 7. Make list_id non-nullable and add foreign key
    change_column_null :categories, :list_id, false
    add_foreign_key :categories, :lists
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
