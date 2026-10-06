require "test_helper"

class CompletedSectionsTest < ActiveSupport::TestCase
  SECTIONS = %i[ completed_today completed_yesterday completed_this_week completed_this_month ].freeze

  def sections_for(task, list)
    found = SECTIONS.select { |scope| list.tasks.public_send(scope).include?(task) }
    found += list.tasks.completed_years.select { |year| list.tasks.completed_in_year(year).include?(task) }.map { |year| "year #{year}" }
    found
  end

  setup do
    @list = lists(:one)
    @list.tasks.destroy_all
  end

  test "every completed task appears in exactly one section" do
    travel_to Time.zone.local(2026, 10, 20, 15, 0) do # a Tuesday afternoon, mid-month
      expected = {
        Time.zone.local(2026, 10, 20, 9, 0) => [ :completed_today ],
        Time.zone.local(2026, 10, 19, 9, 0) => [ :completed_yesterday ], # yesterday morning: previously also "this week"
        Time.zone.local(2026, 10, 19, 20, 0) => [ :completed_yesterday ],
        Time.zone.local(2026, 10, 14, 9, 0) => [ :completed_this_week ],  # 6 days ago, morning
        Time.zone.local(2026, 10, 14, 20, 0) => [ :completed_this_week ], # 6 days ago, evening
        Time.zone.local(2026, 10, 13, 12, 0) => [ :completed_this_month ],
        Time.zone.local(2026, 10, 1, 12, 0) => [ :completed_this_month ],
        Time.zone.local(2026, 9, 15, 12, 0) => [ "year 2026" ],
        Time.zone.local(2025, 6, 1, 12, 0) => [ "year 2025" ]
      }
      expected.each do |at, sections|
        task = @list.tasks.create!(description: at.to_s, completed_on: at)
        assert_equal sections, sections_for(task, @list), "completed #{at}"
      end
    end
  end

  test "early in the month, last month's recent tasks stay in this week rather than a year section" do
    travel_to Time.zone.local(2026, 10, 2, 15, 0) do
      task = @list.tasks.create!(description: "Sept 29", completed_on: Time.zone.local(2026, 9, 29, 12, 0))
      assert_equal [ :completed_this_week ], sections_for(task, @list)
    end
  end

  test "years are counted in the user's time zone" do
    Time.use_zone("Pacific Time (US & Canada)") do
      travel_to Time.zone.local(2027, 3, 1, 12, 0) do
        # 20:00 on New Year's Eve in Los Angeles is already 2027 in UTC
        task = @list.tasks.create!(description: "NYE", completed_on: Time.zone.local(2026, 12, 31, 20, 0))
        assert_equal [ "year 2026" ], sections_for(task, @list)
      end
    end
  end

  test "the last seven days is today, yesterday and this week together" do
    travel_to Time.zone.local(2026, 10, 20, 15, 0) do
      [ 0, 1, 6, 7 ].each { |days| @list.tasks.create!(description: "#{days} ago", completed_on: days.days.ago) }
      assert_equal 3, @list.tasks.completed_in_last_seven_days.count
    end
  end
end
