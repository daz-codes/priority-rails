class AddFatFingerModeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :fat_finger_mode, :boolean, default: false, null: false
  end
end
