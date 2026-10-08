# One browser or device that has turned on notifications (Web Push)
class PushSubscription < ApplicationRecord
  # Only the browsers' push services, so the server can't be pointed at arbitrary URLs
  PUSH_SERVICE_HOSTS = [
    /\Afcm\.googleapis\.com\z/,             # Chrome, Edge (and other Chromium browsers), Android
    /\A[\w-]+\.push\.apple\.com\z/,         # Safari on Mac, iPhone and iPad
    /\Aupdates\.push\.services\.mozilla\.com\z/,
    /\A[\w-]+\.notify\.windows\.com\z/
  ].freeze

  belongs_to :user

  validates :p256dh_key, :auth_key, presence: true
  validates :endpoint, presence: true, uniqueness: true
  validate :endpoint_is_a_push_service

  def self.vapid = Rails.application.credentials.vapid
  def self.public_key = vapid&.dig(:public_key)
  def self.enabled? = public_key.present?

  # Sends one notification. Subscriptions the push service says are gone (the user turned
  # notifications off, or uninstalled the app) are deleted.
  def deliver(payload)
    WebPush.payload_send(
      message: payload.to_json,
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: self.class.vapid.slice(:subject, :public_key, :private_key),
      ttl: 1.day.to_i,
      urgency: "normal"
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    destroy
  end

  private

  def endpoint_is_a_push_service
    uri = URI.parse(endpoint.to_s)
    return if uri.scheme == "https" && PUSH_SERVICE_HOSTS.any? { |host| host.match?(uri.host.to_s) }

    errors.add(:endpoint, "must be a browser push service")
  rescue URI::InvalidURIError
    errors.add(:endpoint, "is invalid")
  end
end
