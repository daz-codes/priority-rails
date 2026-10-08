class AddRecurrenceIntervalToTasks < ActiveRecord::Migration[8.1]
  def change
    # 2 for "every other day/week"
    add_column :tasks, :recurrence_interval, :integer, default: 1, null: false
  end
end
