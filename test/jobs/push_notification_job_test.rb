require "test_helper"
require "minitest/mock"

class PushNotificationJobTest < ActiveJob::TestCase
  test "delivers to every device of each recipient, carrying on past a failing one" do
    user = users(:two)
    phone = user.push_subscriptions.create!(endpoint: "https://web.push.apple.com/phone", p256dh_key: "k", auth_key: "a")
    laptop = user.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/laptop", p256dh_key: "k", auth_key: "a")
    sent = []
    failure = WebPush::ResponseError.new(Struct.new(:body).new("busy"), "web.push.apple.com")
    fake_send = ->(endpoint:, **) { endpoint.include?("phone") ? raise(failure) : sent << endpoint }

    PushSubscription.stub(:vapid, { subject: "https://example.com", public_key: "pub", private_key: "priv" }) do
      WebPush.stub(:payload_send, fake_send) do
        PushNotificationJob.perform_now([ user.id ], { "title" => "Home", "body" => "Hi" })
      end
    end

    assert_equal [ laptop.endpoint ], sent
    assert PushSubscription.exists?(phone.id), "a temporary failure shouldn't delete the subscription"
  end
end
