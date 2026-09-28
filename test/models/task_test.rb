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

    assert_equal task, task.next_occurrence.previous_occurrence
  end

  test "recurrence month must be a real month" do
    task = tasks(:one)
    task.recurrence_type = "yearly"

    task.recurrence_month = 12
    assert task.valid?

    task.recurrence_month = 13
    assert_not task.valid?
  end
end
