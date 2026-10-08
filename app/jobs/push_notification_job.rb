class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_ids, payload)
    return unless PushSubscription.enabled?

    PushSubscription.where(user_id: user_ids).find_each do |subscription|
      subscription.deliver(payload.symbolize_keys)
    rescue WebPush::ResponseError => error
      # A push service hiccup for one device shouldn't stop the rest, or retry them all
      Rails.logger.warn("Push to subscription #{subscription.id} failed: #{error.message}")
    end
  end
end
