require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = lists(:one)
    @owner = users(:one)
    @member = users(:two)
  end

  test "owner can remove a member" do
    sign_in_as @owner
    delete list_membership_url(@list, @member)

    assert_redirected_to edit_list_url(@list)
    assert_not_includes @list.reload.users, @member
  end

  test "a member cannot remove someone else" do
    sign_in_as @member
    delete list_membership_url(@list, @owner)

    assert_redirected_to edit_list_url(@list)
    assert_includes @list.reload.users, @owner
  end

  test "a member can leave" do
    sign_in_as @member
    delete list_membership_url(@list, @member)

    assert_redirected_to root_url
    assert_not_includes @list.reload.users, @member
  end

  test "the owner cannot leave without handing over ownership" do
    sign_in_as @owner
    delete list_membership_url(@list, @owner)

    assert_redirected_to edit_list_url(@list)
    assert_includes @list.reload.users, @owner
  end

  test "owner can transfer ownership and then leave" do
    sign_in_as @owner
    patch transfer_list_membership_url(@list, @member)
    assert_equal @member, @list.reload.owner

    delete list_membership_url(@list, @owner)
    assert_not_includes @list.reload.users, @owner
  end

  test "a member cannot transfer ownership" do
    sign_in_as @member
    patch transfer_list_membership_url(@list, @member)

    assert_equal @owner, @list.reload.owner
  end

  test "cannot manage members of a list you don't belong to" do
    sign_in_as @owner
    delete list_membership_url(lists(:two), @member)
    assert_response :not_found
  end
end
