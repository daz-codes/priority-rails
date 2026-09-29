require "test_helper"

class Account::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_device = @user.sessions.create!(user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/604.1", ip_address: "10.0.0.1")
    sign_in_as @user
  end

  test "profile lists active devices" do
    get edit_account_url

    assert_select "##{ActionView::RecordIdentifier.dom_id(@other_device)}", text: /Safari on iPhone/
    assert_select "li", text: /This device/
  end

  test "sign out one other device" do
    delete account_session_url(@other_device)

    assert_redirected_to edit_account_url
    assert_not Session.exists?(@other_device.id)
  end

  test "sign out all other devices keeps the current one" do
    @user.sessions.create!(user_agent: "Firefox/120", ip_address: "10.0.0.2")

    delete others_account_sessions_url

    assert_equal 1, @user.sessions.count
    get edit_account_url
    assert_response :success
  end

  test "cannot sign out another user's session" do
    theirs = users(:two).sessions.create!

    delete account_session_url(theirs)

    assert_response :not_found
    assert Session.exists?(theirs.id)
  end
end
