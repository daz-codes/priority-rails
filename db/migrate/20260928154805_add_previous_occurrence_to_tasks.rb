class AddPreviousOccurrenceToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :previous_occurrence, foreign_key: { to_table: :tasks, on_delete: :nullify }
  end
end
