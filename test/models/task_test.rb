require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "recurrence type must be a known value" do
    task = tasks(:one)

    (Task::RECURRENCE_TYPES + [ nil ]).each do |type|
      task.recurrence_type = type
      assert task.valid?, "#{type.inspect} should be valid"
    end

    task.recurrence_type = "hourly"
    assert_not task.valid?
  end

  test "completing a recurring task twice only creates one next occurrence" do
    task = lists(:one).tasks.create!(description: "Water plants", recurrence_type: "daily")

    assert_difference("Task.count", 1) do
      task.update!(completed: true)
      task.update!(completed: false)
      task.update!(completed: true)
    end

    assert_equal task, task.reload_next_occurrence.previous_occurrence
  end

  test "undoing a completion removes the occurrence it spawned" do
    task = lists(:one).tasks.create!(description: "Water plants", recurrence_type: "daily")
    task.update!(completed: true)
    spawned = task.reload_next_occurrence

    task.update!(completed: false)

    assert_not Task.exists?(spawned.id)
  end

  test "a restore token recreates a deleted task once, with its note" do
    list = lists(:one)
    task = list.tasks.create!(description: "Call the bank", category: categories(:two), note: "<p>ask about fees</p>")
    token = task.restore_token
    task.destroy!

    restored = Task.restore(token, lists: list.users.first.lists)

    assert_equal "Call the bank", restored.description
    assert_equal categories(:two), restored.category
    assert_match "ask about fees", restored.note.to_plain_text
  end

  test "a restore token can't put a task into a list the user has left" do
    task = lists(:one).tasks.create!(description: "Private")
    token = task.restore_token
    task.destroy!

    assert_nil Task.restore(token, lists: users(:two).lists.where.not(id: lists(:one).id))
  end

  test "a restore token expires" do
    task = lists(:one).tasks.create!(description: "Old")
    token = task.restore_token
    task.destroy!

    travel Task::RESTORE_WINDOW + 1.minute do
      assert_nil Task.restore(token, lists: List.all)
    end
  end

  def quick_add(text)
    lists(:one).tasks.build(description: text).tap(&:apply_category_hashtag)
  end

  test "a hashtag sets the category and is removed from the description" do
    task = quick_add("Buy milk #home")

    assert_equal categories(:one), task.category
    assert_equal "Buy milk", task.description
  end

  test "hashtags match case-insensitively and anywhere in the text" do
    task = quick_add("Call #WORK about the invoice")

    assert_equal categories(:two), task.category
    assert_equal "Call about the invoice", task.description
  end

  test "hashtags ignore spaces and punctuation in category names" do
    side = lists(:one).categories.create!(name: "Side project")

    assert_equal side, quick_add("Ship it #side-project").category
    assert_equal side, quick_add("Ship it #SideProject").category
  end

  test "unknown hashtags are left in the text" do
    task = quick_add("Book #2 appointment")

    assert_nil task.category
    assert_equal "Book #2 appointment", task.description
  end

  test "the first matching hashtag wins and other tags stay" do
    task = quick_add("Tidy #garage #home #work")

    assert_equal categories(:one), task.category
    assert_equal "Tidy #garage #work", task.description
  end

  test "a # inside a word is not a tag" do
    task = quick_add("Learn C#home and issue#work")

    assert_nil task.category
    assert_equal "Learn C#home and issue#work", task.description
  end

  test "only categories from the task's own list match" do
    assert_nil lists(:two).tasks.build(description: "Thing #home").tap(&:apply_category_hashtag).category
  end

  test "recurrence month must be a real month" do
    task = tasks(:one)
    task.recurrence_type = "yearly"

    task.recurrence_month = 12
    assert task.valid?

    task.recurrence_month = 13
    assert_not task.valid?
  end

  def recurring(type, day: nil, interval: 1)
    lists(:one).tasks.build(description: "x", recurrence_type: type, recurrence_day: day, recurrence_interval: interval)
  end

  test "next occurrence for every other day and every other week" do
    travel_to Time.zone.local(2026, 10, 8, 12) do # Thursday
      assert_equal Date.new(2026, 10, 10), recurring("daily", interval: 2).next_occurrence_date
      assert_equal Date.new(2026, 10, 12), recurring("weekly", day: 1).next_occurrence_date # next Monday
      assert_equal Date.new(2026, 10, 19), recurring("weekly", day: 1, interval: 2).next_occurrence_date # the one after
    end
  end

  test "weekdays recur Monday to Friday" do
    travel_to Time.zone.local(2026, 10, 9, 12) do # Friday
      assert_equal Date.new(2026, 10, 12), recurring("weekdays").next_occurrence_date
      assert recurring("weekdays").occurs_on?(Date.new(2026, 10, 9))
      assert_not recurring("weekdays").occurs_on?(Date.new(2026, 10, 10))
      assert_equal "Every weekday", recurring("weekdays").recurrence_label
    end
  end

  test "the interval carries over to the next occurrence" do
    task = lists(:one).tasks.create!(description: "Gym", recurrence_type: "daily", recurrence_interval: 2)
    task.update!(completed: true)

    assert_equal 2, task.reload_next_occurrence.recurrence_interval
    assert_equal "Every other day", task.next_occurrence.recurrence_label
  end

  test "skipping moves a recurring task on to its next occurrence" do
    travel_to Time.zone.local(2026, 10, 8, 12) do
      task = lists(:one).tasks.create!(description: "Get milk", recurrence_type: "weekly", recurrence_day: 1)
      task.skip!
      assert_equal Time.zone.local(2026, 10, 12), task.reload.snoozed_until
      assert_not task.completed?
    end
  end
end
