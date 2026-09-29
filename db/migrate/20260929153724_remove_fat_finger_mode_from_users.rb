class RemoveFatFingerModeFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :fat_finger_mode, :boolean, default: false, null: false
  end
end
