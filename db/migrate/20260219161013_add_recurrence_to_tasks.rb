class AddRecurrenceToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :recurrence_type, :string
    add_column :tasks, :recurrence_day, :integer
    add_column :tasks, :recurrence_month, :integer
  end
end
