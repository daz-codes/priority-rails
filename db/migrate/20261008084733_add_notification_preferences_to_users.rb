class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notify_on_list_activity, :boolean, default: true, null: false
    add_column :users, :notify_on_list_invites, :boolean, default: true, null: false
  end
end
