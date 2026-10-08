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

  test "quick add hashtag sets the category" do
    post list_tasks_url(@list), params: { task: { description: "Buy milk #home" } }

    task = @list.tasks.last
    assert_equal "Buy milk", task.description
    assert_equal categories(:one), task.category
  end

  test "quick add recurrence: the first occurrence waits for its day" do
    travel_to Time.zone.local(2026, 10, 7, 15) do # a Wednesday
      post list_tasks_url(@list), params: { task: { description: "Get milk every monday #home" } }
    end

    task = @list.tasks.last
    assert_equal [ "Get milk", "weekly", 1 ], [ task.description, task.recurrence_type, task.recurrence_day ]
    assert_equal categories(:one), task.category
    assert_equal Time.zone.local(2026, 10, 12), task.snoozed_until # the next Monday
  end

  test "quick add recurrence shows straight away when today is the day" do
    travel_to Time.zone.local(2026, 10, 12, 9) do # a Monday
      post list_tasks_url(@list), params: { task: { description: "Get milk #home every monday" } }
    end

    task = @list.tasks.last
    assert_equal "Get milk", task.description
    assert_nil task.snoozed_until
  end

  test "skip this time snoozes a recurring task until its next occurrence, with a toast" do
    task = @list.tasks.create!(description: "Get milk", recurrence_type: "daily")

    patch skip_task_url(task), as: :turbo_stream

    assert_equal Date.tomorrow.beginning_of_day, task.reload.snoozed_until
    assert_select "turbo-stream template [data-toast]", text: /Skipped until/
  end

  test "only recurring tasks can be skipped" do
    patch skip_task_url(@task), as: :turbo_stream
    assert_response :unprocessable_entity
  end

  test "a task that is only a hashtag is rejected as blank" do
    assert_no_difference("Task.count") do
      post list_tasks_url(@list), params: { task: { description: "#home" } }
    end
    assert_equal "Description can't be blank", flash[:alert]
  end

  test "creating a blank task redirects back with an error" do
    assert_no_difference("Task.count") do
      post list_tasks_url(@list), params: { task: { description: "" } }
    end

    assert_redirected_to list_url(@list)
    assert_equal "Description can't be blank", flash[:alert]
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

  test "sort reorders the user's own tasks" do
    other = @list.tasks.create!(description: "Another task")

    patch sort_tasks_url, params: { task_ids: [ other.id, @task.id ] }, as: :json

    assert_response :ok
    assert_equal 1, other.reload.position
    assert_equal 2, @task.reload.position
  end

  test "sort cannot touch tasks on another user's list" do
    foreign = tasks(:two)
    original_position = foreign.position

    patch sort_tasks_url, params: { task_ids: [ @task.id, foreign.id ] }, as: :json

    assert_response :not_found
    assert_equal original_position, foreign.reload.position
  end

  def build_list(spec)
    @list.tasks.destroy_all
    home, work = categories(:one), categories(:two)
    spec.split.map { |name| @list.tasks.create!(description: name, category: name.start_with?("A") ? home : work) }
  end

  def order = @list.tasks.ordered.pluck(:description).join(" ")

  test "sorting a category-filtered view keeps the other tasks in place" do
    tasks = build_list("A1 B2 B3 B4 A5 B6").index_by(&:description)

    patch sort_tasks_url, params: { task_ids: tasks.values_at("B3", "B2", "B4", "B6").map(&:id) }, as: :json

    assert_response :ok
    assert_equal "A1 B3 B2 B4 A5 B6", order
  end

  test "moving a filtered task to the end puts it in the last slot its category holds" do
    tasks = build_list("A1 B2 B3 B4 A5 B6").index_by(&:description)

    patch sort_tasks_url, params: { task_ids: tasks.values_at("B3", "B4", "B6", "B2").map(&:id) }, as: :json

    assert_equal "A1 B3 B4 B6 A5 B2", order
  end

  test "snoozed tasks hidden from the inbox keep their place when sorting" do
    tasks = build_list("A1 A2 A3").index_by(&:description)
    tasks["A2"].update!(snoozed_until: 1.day.from_now)

    patch sort_tasks_url, params: { task_ids: tasks.values_at("A3", "A1").map(&:id) }, as: :json

    assert_equal "A3 A2 A1", order
  end

  test "sort rejects tasks from more than one list" do
    other_list = @user.lists.create!(name: "Other", owner: @user)
    elsewhere = other_list.tasks.create!(description: "Elsewhere")

    patch sort_tasks_url, params: { task_ids: [ @task.id, elsewhere.id ] }, as: :json

    assert_response :unprocessable_entity
  end

  test "sort without task ids does nothing" do
    patch sort_tasks_url, as: :json

    assert_response :ok
  end

  test "update cannot move a task to another user's list" do
    patch task_url(@task), params: { task: { list_id: lists(:two).id } }

    assert_equal @list, @task.reload.list
  end

  test "update rejects a category from another list" do
    patch task_url(@task), params: { task: { category_id: categories(:three).id } }

    assert_response :unprocessable_entity
    assert_equal categories(:two), @task.reload.category
  end

  test "move sends a task to another of the user's lists, keeping a matching category" do
    destination = @user.lists.create!(name: "Other", owner: @user)
    home = categories(:one)
    @task.update!(category: home)

    patch move_task_url(@task), params: { list_id: destination.id }

    assert_redirected_to list_url(@list)
    @task.reload
    assert_equal destination, @task.list
    assert_equal destination.categories.find_by(name: home.name), @task.category
  end

  test "moving falls back to the destination's default category when names don't match" do
    destination = @user.lists.create!(name: "Other", owner: @user)
    @task.update!(category: @list.categories.create!(name: "Errands"))

    patch move_task_url(@task), params: { list_id: destination.id }

    assert_equal destination.default_category, @task.reload.category
  end

  test "moved tasks go to the end of the destination list" do
    destination = @user.lists.create!(name: "Other", owner: @user)
    existing = destination.tasks.create!(description: "Already here")

    patch move_task_url(@task), params: { list_id: destination.id }

    assert_equal existing.reload.position + 1, @task.reload.position
  end

  test "cannot move a task to a list the user isn't on" do
    patch move_task_url(@task), params: { list_id: lists(:two).id }

    assert_response :not_found
    assert_equal @list, @task.reload.list
  end

  test "JSON updates from Helium refresh the page instead of redirecting" do
    patch task_url(@task), params: { task: { snoozed_until: 1.day.from_now } }, as: :json

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=refresh]:not([request-id])"
  end

  test "snoozing until a chosen date wakes at the start of that day in the user's zone" do
    @user.update!(time_zone: "Tokyo")

    patch task_url(@task), params: { task: { snoozed_until: "2030-03-14" } }, as: :json

    assert_equal Time.find_zone("Tokyo").local(2030, 3, 14), @task.reload.snoozed_until
  end

  test "completing a task doesn't show a toast" do
    @task.update!(completed: false)

    patch task_url(@task), params: { task: { completed: true } }, as: :turbo_stream

    assert_response :redirect
    assert @task.reload.completed?
  end

  test "editing a description via Turbo still redirects" do
    patch task_url(@task), params: { task: { description: "Renamed" } }, as: :turbo_stream

    assert_response :redirect
  end

  test "deleting via Turbo removes the row and offers undo, which restores the task" do
    delete task_url(@task), as: :turbo_stream

    assert_select "turbo-stream[action=remove][target=#{ActionView::RecordIdentifier.dom_id(@task)}]"
    token = css_select("turbo-stream template input[name=token]").first["value"]

    assert_difference("Task.count") do
      post restore_tasks_url, params: { token: token }, as: :turbo_stream
    end
    assert_equal @task.description, @list.tasks.last.description
  end

  test "restoring with a bad token fails" do
    post restore_tasks_url, params: { token: "nope" }, as: :turbo_stream

    assert_response :gone
  end

  test "moving via Turbo offers an undo that moves it back" do
    destination = @user.lists.create!(name: "Other", owner: @user)

    patch move_task_url(@task), params: { list_id: destination.id }, as: :turbo_stream

    assert_select "turbo-stream template [data-toast]", text: /Moved to Other/
    assert_select "turbo-stream template input[name=list_id][value=#{@list.id}]"
  end

  test "the task panel saves name, note and list together" do
    destination = @user.lists.create!(name: "Other", owner: @user)

    patch task_url(@task), params: { task: { description: "Renamed", note: "<p>details</p>", list_id: destination.id } }, as: :turbo_stream

    @task.reload
    assert_equal "Renamed", @task.description
    assert_match "details", @task.note.to_plain_text
    assert_equal destination, @task.list
    assert_select "turbo-stream template [data-toast]", text: /Moved to Other/
  end

  test "saving the panel without changing list just redirects back" do
    patch task_url(@task), params: { task: { description: "Renamed", list_id: @list.id } }, as: :turbo_stream

    assert_response :redirect
    assert_equal @list, @task.reload.list
  end

  test "the panel form can't move a task to someone else's list" do
    patch task_url(@task), params: { task: { description: "Sneaky", list_id: lists(:two).id } }

    assert_response :not_found
    assert_equal @list, @task.reload.list
    assert_not_equal "Sneaky", @task.description
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
