class AddNameAndLastListToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :last_list_id, :integer
  end
end
