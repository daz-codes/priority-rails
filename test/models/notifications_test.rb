require "test_helper"
require "minitest/mock"

class NotificationsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @list = lists(:one) # users one (owner) and two
    @owner = users(:one)
    @member = users(:two)
    @member.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/member", p256dh_key: "k", auth_key: "a")
    @task = @list.tasks.create!(description: "Buy milk")
  end

  def with_push_enabled(&) = PushSubscription.stub(:enabled?, true, &)

  test "adding a task notifies the other members, not the person who added it" do
    with_push_enabled do
      assert_enqueued_with(job: PushNotificationJob, args: [ [ @member.id ], {
        title: @list.name, body: "#{@owner.name} added “Buy milk”", url: "/lists/#{@list.id}", tag: "list-#{@list.id}"
      } ]) do
        Notifications.task_added(@task, by: @owner)
      end
    end
  end

  test "completing a task notifies the other members" do
    with_push_enabled do
      assert_enqueued_jobs 1, only: PushNotificationJob do
        Notifications.task_completed(@task, by: @owner)
      end
    end
  end

  test "nobody is notified about their own changes" do
    @owner.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/owner", p256dh_key: "k", auth_key: "a")
    @member.push_subscriptions.destroy_all

    with_push_enabled do
      assert_no_enqueued_jobs { Notifications.task_added(@task, by: @owner) }
    end
  end

  test "members who turned off list activity aren't notified" do
    @member.update!(notify_on_list_activity: false)

    with_push_enabled do
      assert_no_enqueued_jobs { Notifications.task_added(@task, by: @owner) }
    end
  end

  test "being added to a list notifies that person, if they want it" do
    with_push_enabled do
      assert_enqueued_with(job: PushNotificationJob, args: [ [ @member.id ], {
        title: "PR!OR!TY!", body: "#{@owner.name} added you to #{@list.name}", url: "/lists/#{@list.id}"
      } ]) do
        Notifications.added_to_list(@list, user: @member, by: @owner)
      end

      @member.update!(notify_on_list_invites: false)
      assert_no_enqueued_jobs { Notifications.added_to_list(@list, user: @member, by: @owner) }
    end
  end

  test "nothing is sent when push isn't configured" do
    PushSubscription.stub(:enabled?, false) do
      assert_no_enqueued_jobs { Notifications.task_added(@task, by: @owner) }
    end
  end
end
