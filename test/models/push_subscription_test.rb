require "test_helper"
require "minitest/mock"

class PushSubscriptionTest < ActiveSupport::TestCase
  def build(endpoint)
    users(:one).push_subscriptions.build(endpoint: endpoint, p256dh_key: "p256dh", auth_key: "auth")
  end

  test "accepts the browsers' push services" do
    %w[
      https://fcm.googleapis.com/fcm/send/abc123
      https://web.push.apple.com/QGuQyavXutnMH
      https://updates.push.services.mozilla.com/wpush/v2/gAAAA
      https://wns2-par02p.notify.windows.com/w/?token=abc
    ].each { |endpoint| assert build(endpoint).valid?, endpoint }
  end

  test "rejects anything else, so the server can't be pointed at arbitrary URLs" do
    %w[
      http://fcm.googleapis.com/fcm/send/abc
      https://example.com/push
      https://fcm.googleapis.com.evil.example/push
      https://localhost/push
      https://169.254.169.254/latest/meta-data
      not-a-url
    ].each { |endpoint| assert_not build(endpoint).valid?, endpoint }
  end

  test "a subscription the push service says has expired is deleted" do
    subscription = build("https://fcm.googleapis.com/fcm/send/abc").tap(&:save!)
    expired = WebPush::ExpiredSubscription.new(Struct.new(:body).new("gone"), "fcm.googleapis.com")

    PushSubscription.stub(:vapid, { subject: "https://example.com", public_key: "pub", private_key: "priv" }) do
      WebPush.stub(:payload_send, ->(**) { raise expired }) do
        subscription.deliver(title: "Hi")
      end
    end

    assert_not PushSubscription.exists?(subscription.id)
  end
end
