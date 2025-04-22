class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :description, null: false
      t.integer :position
      t.string :category
      t.datetime :completed_on
      t.datetime :snoozed_until
      t.belongs_to :list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
