class AddCompletedOnIndexToTasks < ActiveRecord::Migration[8.0]
  def change
    add_index :tasks, [ :list_id, :completed_on ]
  end
end
