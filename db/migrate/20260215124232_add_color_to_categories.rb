class AddColorToCategories < ActiveRecord::Migration[8.0]
  def up
    add_column :categories, :color, :string, default: "#a5f3fc"

    execute "UPDATE categories SET color = '#a5f3fc' WHERE name = 'Home'"
    execute "UPDATE categories SET color = '#d9f99d' WHERE name = 'Work'"
    execute "UPDATE categories SET color = '#fef08a' WHERE name = 'Hobbies'"
  end

  def down
    remove_column :categories, :color
  end
end
