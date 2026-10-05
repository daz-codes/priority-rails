require "test_helper"

class TasksHelperTest < ActionView::TestCase
  test "snoozes wake at the start of the day in the user's zone" do
    Time.use_zone("London") do
      travel_to Time.zone.local(2026, 10, 5, 16, 44) do # Monday afternoon
        assert_equal Time.zone.local(2026, 10, 6), snooze_until(1.day)
        assert_equal Time.zone.local(2026, 10, 8), snooze_until(3.days) # Thursday 00:00, not 16:44
        assert_equal Time.zone.local(2026, 10, 12), snooze_until(1.week)
        assert_equal Time.zone.local(2026, 11, 5), snooze_until(1.month)
      end
    end
  end

  test "late at night it still means the following day in the user's zone" do
    Time.use_zone("Pacific Time (US & Canada)") do
      travel_to Time.utc(2026, 10, 6, 6, 30) do # 23:30 on the 5th in Los Angeles
        assert_equal Time.zone.local(2026, 10, 6), snooze_until(1.day)
      end
    end
  end
end
