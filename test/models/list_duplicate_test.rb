require "test_helper"

class ListDuplicateTest < ActiveSupport::TestCase
  setup do
    @list = lists(:one) # owner: one, also shared with two; categories Home (one) and Work (two, default)
    @list.tasks.destroy_all
    @list.update!(focus_limit: 5, completed_display: "1_week")
    @user = users(:two)
  end

  test "copies categories, settings and tasks, with every task starting again" do
    @list.tasks.create!(description: "Passport", category: categories(:one), completed: true, note: "<p>check expiry</p>")
    @list.tasks.create!(description: "Charger", category: categories(:two), snoozed_until: 2.days.from_now)
    @list.tasks.create!(description: "Water plants", recurrence_type: "weekly", recurrence_day: 1, recurrence_interval: 2)

    copy = @list.duplicate(name: "Packing", owner: @user)

    assert_equal "Packing", copy.name
    assert_equal [ 5, "1_week" ], [ copy.focus_limit, copy.completed_display ]
    assert_equal [ [ "Home", categories(:one).color ], [ "Work", categories(:two).color ] ], copy.categories.order(:name).pluck(:name, :color)
    assert_equal "Work", copy.default_category.name

    tasks = copy.tasks.ordered.to_a
    assert_equal [ "Passport", "Charger", "Water plants" ], tasks.map(&:description)
    assert tasks.none?(&:completed?)
    assert tasks.none?(&:snoozed?)
    assert_equal "Home", tasks.first.category.name
    assert_match "check expiry", tasks.first.note.to_plain_text
    assert_equal [ "weekly", 1, 2 ], [ tasks.last.recurrence_type, tasks.last.recurrence_day, tasks.last.recurrence_interval ]
  end

  test "a recurring task's past occurrences aren't copied, only the latest" do
    task = @list.tasks.create!(description: "Water plants", recurrence_type: "daily")
    task.update!(completed: true) # creates the next occurrence

    copy = @list.duplicate(name: "Copy", owner: @user)

    assert_equal [ "Water plants" ], copy.tasks.pluck(:description)
  end

  test "the copy belongs only to the person who made it, without default categories added" do
    copy = @list.duplicate(name: "Mine", owner: @user)

    assert_equal [ @user ], copy.users.to_a
    assert_equal @user, copy.owner
    assert_equal %w[Home Work], copy.categories.order(:name).pluck(:name)
    assert_not copy.archived?
  end
end
