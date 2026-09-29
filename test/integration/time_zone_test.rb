require "test_helper"

class TimeZoneTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @list = lists(:one)
    sign_in_as @user
  end

  test "completion days follow the user's zone, not UTC" do
    @user.update!(time_zone: "Pacific Time (US & Canada)")
    # 11pm on the 28th in Los Angeles, but already the 29th in UTC
    task = @list.tasks.create!(description: "Late night task", completed_on: Time.utc(2026, 9, 29, 6, 0))

    # 1pm on the 29th in Los Angeles: the task was done yesterday, not today
    travel_to Time.utc(2026, 9, 29, 20, 0) do
      get list_url(@list, list: "completed")
    end

    task_row = "li##{ActionView::RecordIdentifier.dom_id(task)}"
    assert_select "h3:contains('Yesterday') + ul #{task_row}"
    assert_select "h3:contains('Today') + ul #{task_row}", count: 0
  end

  test "recurring tasks wake up at midnight in the user's zone" do
    @user.update!(time_zone: "Tokyo")
    task = @list.tasks.create!(description: "Daily", recurrence_type: "daily")

    travel_to Time.utc(2026, 9, 30, 12, 0) do
      patch task_url(task), params: { task: { completed: true } }
    end

    assert_equal Time.find_zone("Tokyo").local(2026, 10, 1), task.next_occurrence.snoozed_until
  end

  test "time zone can be changed on the profile" do
    patch account_url, params: { user: { time_zone: "London" } }

    assert_equal "London", @user.reload.time_zone
  end

  test "rejects unknown zones" do
    assert_not @user.update(time_zone: "Mars/Olympus")
  end
end
