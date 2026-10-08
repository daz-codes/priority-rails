class MakeTimeZoneOptional < ActiveRecord::Migration[8.1]
  # An empty time zone means "not set yet": the browser's zone is filled in on the next visit.
  # Accounts still on the old UTC default never chose it, so they're treated as not set.
  def up
    change_column_default :users, :time_zone, from: "UTC", to: nil
    change_column_null :users, :time_zone, true
    execute "UPDATE users SET time_zone = NULL WHERE time_zone = 'UTC'"
  end

  def down
    execute "UPDATE users SET time_zone = 'UTC' WHERE time_zone IS NULL"
    change_column_null :users, :time_zone, false
    change_column_default :users, :time_zone, from: nil, to: "UTC"
  end
end
