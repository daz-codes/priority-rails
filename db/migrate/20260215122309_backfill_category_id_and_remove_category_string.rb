class BackfillCategoryIdAndRemoveCategoryString < ActiveRecord::Migration[8.0]
  def up
    # Ensure default categories exist
    %w[Home Work Hobbies].each do |name|
      execute "INSERT OR IGNORE INTO categories (name, created_at, updated_at) VALUES ('#{name}', datetime('now'), datetime('now'))"
    end

    # Ensure all lists have the default categories assigned
    execute <<~SQL
      INSERT OR IGNORE INTO list_categories (list_id, category_id, created_at, updated_at)
      SELECT l.id, c.id, datetime('now'), datetime('now')
      FROM lists l
      CROSS JOIN categories c
      WHERE c.name IN ('Home', 'Work', 'Hobbies')
    SQL

    # Backfill category_id from the category string column
    execute <<~SQL
      UPDATE tasks
      SET category_id = (
        SELECT c.id FROM categories c WHERE c.name = tasks.category
      )
      WHERE category IS NOT NULL AND category != '' AND category_id IS NULL
    SQL

    # Default remaining tasks (no match) to "Work"
    execute <<~SQL
      UPDATE tasks
      SET category_id = (SELECT id FROM categories WHERE name = 'Work')
      WHERE category_id IS NULL
    SQL

    remove_column :tasks, :category
  end

  def down
    add_column :tasks, :category, :string

    execute <<~SQL
      UPDATE tasks
      SET category = (
        SELECT c.name FROM categories c WHERE c.id = tasks.category_id
      )
      WHERE category_id IS NOT NULL
    SQL
  end
end
