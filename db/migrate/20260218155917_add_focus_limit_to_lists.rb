class AddFocusLimitToLists < ActiveRecord::Migration[8.0]
  def change
    add_column :lists, :focus_limit, :integer, default: 3, null: false
  end
end
