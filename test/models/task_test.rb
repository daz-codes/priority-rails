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

  test "recurrence month must be a real month" do
    task = tasks(:one)
    task.recurrence_type = "yearly"

    task.recurrence_month = 12
    assert task.valid?

    task.recurrence_month = 13
    assert_not task.valid?
  end
end
