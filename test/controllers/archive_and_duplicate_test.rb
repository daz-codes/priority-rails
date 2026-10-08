require "test_helper"

class ArchiveAndDuplicateTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @list = lists(:one)
    @other = @owner.lists.create!(name: "Groceries", owner: @owner)
    sign_in_as @owner
  end

  test "archiving hides a list from the menu and the start page, and unarchiving brings it back" do
    post archive_list_url(@list)
    assert_redirected_to root_url
    assert @list.reload.archived?

    get list_url(@other)
    assert_select "[data-menu-list] a", text: @list.name, count: 0
    assert_select "a[href='#{archived_lists_path}']", text: /Archived Lists \(1\)/

    @owner.update_column(:last_list_id, @list.id)
    get root_url
    assert_redirected_to list_url(@other), "shouldn't reopen an archived list"

    get archived_lists_url
    assert_select "#archived_list_#{@list.id}", text: /#{@list.name}/

    post unarchive_list_url(@list)
    assert_redirected_to list_url(@list)
    assert_not @list.reload.archived?
  end

  test "an archived list can still be opened, and says so" do
    @list.archive!
    get list_url(@list)
    assert_response :success
    assert_select "[data-archived-banner]", text: /archived/
  end

  test "only the owner can archive" do
    delete session_url
    sign_in_as users(:two)

    post archive_list_url(@list)

    assert_redirected_to edit_list_url(@list)
    assert_not @list.reload.archived?
  end

  test "any member can duplicate a list into their own copy" do
    delete session_url
    sign_in_as users(:two)

    assert_difference("List.count") do
      post duplicate_list_url(@list), params: { name: "My copy" }
    end
    copy = List.last
    assert_redirected_to list_url(copy)
    assert_equal [ "My copy", [ users(:two) ] ], [ copy.name, copy.users.to_a ]
  end

  test "duplicating without a name uses the original's name with (copy)" do
    post duplicate_list_url(@list)
    assert_equal "#{@list.name} (copy)", List.last.name
  end

  test "archived lists aren't offered as places to move a task" do
    @other.archive!
    task = @list.tasks.create!(description: "Thing")

    get edit_task_url(task)

    assert_select "select[name='task[list_id]'] option", text: "Groceries", count: 0
  end
end
