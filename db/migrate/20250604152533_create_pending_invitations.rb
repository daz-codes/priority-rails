class CreatePendingInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_invitations do |t|
      t.string :email
      t.references :list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
