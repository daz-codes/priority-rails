require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  def subscription(endpoint = "https://fcm.googleapis.com/fcm/send/device1")
    { subscription: { endpoint: endpoint, keys: { p256dh: "BNcRd", auth: "tBHI" } } }
  end

  test "saves this device's subscription" do
    assert_difference("PushSubscription.count") do
      post push_subscription_url, params: subscription, as: :json
    end
    assert_response :created
    assert_equal @user, PushSubscription.last.user
  end

  test "rejects an endpoint that isn't a push service" do
    assert_no_difference("PushSubscription.count") do
      post push_subscription_url, params: subscription("https://example.com/hook"), as: :json
    end
    assert_response :unprocessable_entity
  end

  test "a shared device moves to whoever turns notifications on" do
    users(:two).push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/device1", p256dh_key: "old", auth_key: "old")

    assert_no_difference("PushSubscription.count") do
      post push_subscription_url, params: subscription, as: :json
    end
    assert_equal @user, PushSubscription.find_by(endpoint: "https://fcm.googleapis.com/fcm/send/device1").user
  end

  test "turning off removes only your own subscription" do
    mine = @user.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/mine", p256dh_key: "k", auth_key: "a")
    theirs = users(:two).push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/theirs", p256dh_key: "k", auth_key: "a")

    delete push_subscription_url(endpoint: mine.endpoint)
    delete push_subscription_url(endpoint: theirs.endpoint)

    assert_not PushSubscription.exists?(mine.id)
    assert PushSubscription.exists?(theirs.id)
  end

  test "adding a task on a shared list queues a notification for the other member" do
    users(:two).push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/two", p256dh_key: "k", auth_key: "a")

    PushSubscription.stub(:enabled?, true) do
      assert_enqueued_jobs 1, only: PushNotificationJob do
        post list_tasks_url(lists(:one)), params: { task: { description: "Buy milk" } }
      end
    end
  end
end
