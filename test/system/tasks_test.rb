require "application_system_test_case"

class TasksTest < ApplicationSystemTestCase
  setup do
    @task = tasks(:one)
  end

  test "visiting the index" do
    visit tasks_url
    assert_selector "h1", text: "Tasks"
  end

  test "should create task" do
    visit tasks_url
    click_on "New task"

    fill_in "Category", with: @task.category
    fill_in "Completed on", with: @task.completed_on
    fill_in "Description", with: @task.description
    fill_in "List", with: @task.list_id
    fill_in "Position", with: @task.position
    fill_in "Snoozed until", with: @task.snoozed_until
    click_on "Create Task"

    assert_text "Task was successfully created"
    click_on "Back"
  end

  test "should update Task" do
    visit task_url(@task)
    click_on "Edit this task", match: :first

    fill_in "Category", with: @task.category
    fill_in "Completed on", with: @task.completed_on.to_s
    fill_in "Description", with: @task.description
    fill_in "List", with: @task.list_id
    fill_in "Position", with: @task.position
    fill_in "Snoozed until", with: @task.snoozed_until.to_s
    click_on "Update Task"

    assert_text "Task was successfully updated"
    click_on "Back"
  end

  test "should destroy Task" do
    visit task_url(@task)
    click_on "Destroy this task", match: :first

    assert_text "Task was successfully destroyed"
  end
end
