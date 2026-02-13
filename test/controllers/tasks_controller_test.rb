require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @list = lists(:one)
    @task = tasks(:one)
    sign_in_as(@user)
  end

  test "should create task" do
    assert_difference("Task.count") do
      post list_tasks_url(@list), params: { task: { description: "New task" } }
    end

    assert_redirected_to list_url(@list)
  end

  test "should get edit" do
    get edit_task_url(@task)
    assert_response :success
  end

  test "should update task" do
    patch task_url(@task), params: { task: { description: "Updated task" } }
    assert_redirected_to list_url(@list)
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end

    assert_redirected_to list_url(@list)
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
