class Session < ApplicationRecord
  INACTIVITY_TIMEOUT = 30.days
  ACTIVITY_RESOLUTION = 1.hour

  belongs_to :user

  attribute :last_active_at, default: -> { Time.current }

  scope :active, -> { where(last_active_at: INACTIVITY_TIMEOUT.ago..) }
  scope :expired, -> { where(last_active_at: ...INACTIVITY_TIMEOUT.ago) }
  scope :recent_first, -> { order(last_active_at: :desc) }

  # Only write when the stored value is stale, so every request isn't a database write
  def record_activity
    update_column(:last_active_at, Time.current) if last_active_at.before?(ACTIVITY_RESOLUTION.ago)
  end

  def device_description
    [ browser_name, platform_name ].compact.join(" on ").presence || "Unknown device"
  end

  private

  def browser_name
    case user_agent.to_s
    when /Edg\//      then "Edge"
    when /OPR\//      then "Opera"
    when /Firefox\//  then "Firefox"
    when /Chrome\//   then "Chrome"
    when /Safari\//   then "Safari"
    end
  end

  def platform_name
    case user_agent.to_s
    when /iPhone/          then "iPhone"
    when /iPad/            then "iPad"
    when /Android/         then "Android"
    when /Mac OS X/        then "Mac"
    when /Windows/         then "Windows"
    when /Linux/           then "Linux"
    end
  end
end
