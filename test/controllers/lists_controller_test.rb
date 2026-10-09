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

  test "focus mode shows only the tasks and a way back" do
    get list_url(@list, list: "priority")

    assert_select "#today_progress", count: 0
    assert_select "#list_actions", count: 0
    assert_select "#new_task_form", count: 0
    assert_select "[data-menu-toggle]", count: 0
    assert_select "h1", text: @list.name, count: 0
    assert_select "a[data-escape-back][href='#{list_path(@list)}']", text: "Back to inbox"
  end

  test "inbox shows the tabs above the list title" do
    get list_url(@list)

    assert_match(/id="list_actions".*<h1/m, response.body)
    assert_select "[data-menu-toggle]"
  end

  test "should get edit" do
    get edit_list_url(@list)
    assert_response :success
  end

  test "should update list" do
    patch list_url(@list), params: { list: { name: "Updated" } }
    assert_redirected_to list_url(@list)
  end

  test "settings save the categories with the list, adding one when a name is given" do
    home, work = @list.categories.to_a
    patch list_url(@list), params: { list: { name: "Updated", focus_limit: 5, categories_attributes: {
      "0" => { id: home.id, name: "House", color: Category::COLORS.last },
      "1" => { id: work.id, name: work.name, color: work.color },
      "2" => { name: "Garden" }
    } } }

    assert_redirected_to list_url(@list)
    assert_equal [ "House", Category::COLORS.last ], [ home.reload.name, home.color ]
    assert_equal %w[House Work Garden], @list.reload.categories.pluck(:name)
    assert_equal Category::COLORS.first, @list.categories.last.color
  end

  test "a blank new category is ignored, and a clash shows the settings again" do
    home, work = @list.categories.to_a
    assert_no_difference "Category.count" do
      patch list_url(@list), params: { list: { categories_attributes: { "0" => { id: home.id, name: "Home" }, "2" => { name: "" } } } }
    end
    assert_redirected_to list_url(@list)

    patch list_url(@list), params: { list: { name: "Kept?", categories_attributes: { "0" => { id: home.id, name: work.name } } } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /taken/
    assert_equal "Home", home.reload.name
    assert_not_equal "Kept?", @list.reload.name
  end

  test "settings only touch this list's categories" do
    other = categories(:three)
    patch list_url(@list), params: { list: { categories_attributes: { "0" => { id: other.id, name: "Hijacked" } } } }
    assert_response :not_found
    assert_not_equal "Hijacked", other.reload.name
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
