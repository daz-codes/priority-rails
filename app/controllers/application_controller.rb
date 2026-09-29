class ApplicationController < ActionController::Base
  include Authentication
  around_action :use_user_time_zone
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Runs after authentication, so "today", snoozes and recurrences use the user's own day
  def use_user_time_zone(&)
    Time.use_zone(Current.user&.time_zone || "UTC", &)
  end
end
