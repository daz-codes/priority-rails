require "test_helper"

class SessionExpiryTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @session = @user.sessions.last
  end

  test "an inactive session is rejected" do
    @session.update_column(:last_active_at, (Session::INACTIVITY_TIMEOUT + 1.day).ago)

    get list_url(lists(:one))

    assert_redirected_to login_url
  end

  test "activity keeps the session alive" do
    @session.update_column(:last_active_at, 2.days.ago)

    get list_url(lists(:one))

    assert_response :success
    assert_in_delta Time.current, @session.reload.last_active_at, 5.seconds
  end

  test "expired scope finds only stale sessions" do
    @session.update_column(:last_active_at, 31.days.ago)
    fresh = @user.sessions.create!

    assert_includes Session.expired, @session
    assert_not_includes Session.expired, fresh
  end

  test "resetting a password signs out every session" do
    token = @user.password_reset_token

    put password_url(token), params: { password: "newpassword", password_confirmation: "newpassword" }

    assert_redirected_to login_url
    assert_equal 0, @user.sessions.count
  end
end
