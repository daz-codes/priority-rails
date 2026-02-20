class CreateListCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :list_categories do |t|
      t.references :list, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :list_categories, [ :list_id, :category_id ], unique: true
  end
end
