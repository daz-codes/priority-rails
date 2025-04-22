class AddCategoryToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :category, foreign_key: true
  end
end
