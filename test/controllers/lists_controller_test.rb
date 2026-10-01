require "test_helper"

class ListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @list = lists(:one)
    sign_in_as(@user)
  end

  test "should redirect index to last list" do
    get lists_url
    assert_response :redirect
  end

  test "should get new" do
    get new_list_url
    assert_response :success
  end

  test "should create list" do
    assert_difference("List.count") do
      post lists_url, params: { list: { name: "New list" } }
    end

    assert_redirected_to list_url(List.last)
    assert_includes List.last.users, @user
    assert_equal @user, List.last.owner
  end

  test "a member who isn't the owner cannot destroy the list" do
    delete session_url
    sign_in_as users(:two)

    assert_no_difference("List.count") do
      delete list_url(@list)
    end

    assert_redirected_to edit_list_url(@list)
    assert_equal "Only the list owner can delete it.", flash[:alert]
  end

  test "settings show delete to the owner and leave to other members" do
    get edit_list_url(@list)
    assert_select "button", text: "Delete list"
    assert_select "button", text: "Leave list", count: 0

    delete session_url
    sign_in_as users(:two)
    get edit_list_url(@list)
    assert_select "button", text: "Leave list"
    assert_select "button", text: "Delete list", count: 0
  end

  test "inviting a new email creates one invitation and sends mail" do
    assert_difference("PendingInvitation.count") do
      assert_enqueued_emails 1 do
        post add_user_list_url(@list), params: { email_address: " Friend@Example.com " }
      end
    end

    assert_redirected_to list_url(@list)
    assert_equal "friend@example.com", PendingInvitation.last.email
  end

  test "re-inviting the same email does not create a duplicate" do
    assert_no_difference("PendingInvitation.count") do
      post add_user_list_url(@list), params: { email_address: pending_invitations(:one).email }
    end
  end

  test "inviting an invalid email shows an error" do
    assert_no_difference("PendingInvitation.count") do
      post add_user_list_url(@list), params: { email_address: "nope" }
    end

    assert_redirected_to edit_list_url(@list)
    assert_match "Email is invalid", flash[:alert]
  end

  test "should show list" do
    get list_url(@list)
    assert_response :success
  end

  test "inbox shows today's progress, ignoring snoozed tasks" do
    @list.tasks.destroy_all
    @list.tasks.create!(description: "Done today", completed: true)
    @list.tasks.create!(description: "Done last week", completed_on: 8.days.ago)
    @list.tasks.create!(description: "Still to do")
    @list.tasks.create!(description: "Snoozed", snoozed_until: 1.day.from_now)

    get list_url(@list)

    assert_select "#today_progress [role=progressbar][aria-valuenow='1'][aria-valuemax='2']"
    assert_select "#today_progress", text: /1 of 2 done today/
  end

  test "focus mode has no progress bar" do
    get list_url(@list, list: "priority")

    assert_select "#today_progress", count: 0
  end

  test "should get edit" do
    get edit_list_url(@list)
    assert_response :success
  end

  test "should update list" do
    patch list_url(@list), params: { list: { name: "Updated" } }
    assert_redirected_to list_url(@list)
  end

  test "should destroy list" do
    assert_difference("List.count", -1) do
      delete list_url(@list)
    end

    assert_redirected_to lists_url
  end

  private

  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
