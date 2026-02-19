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
  end

  test "should show list" do
    get list_url(@list)
    assert_response :success
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
