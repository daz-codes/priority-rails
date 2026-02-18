class AddCompletedDisplayToLists < ActiveRecord::Migration[8.0]
  def change
    add_column :lists, :completed_display, :string, default: "1_day", null: false
  end
end
