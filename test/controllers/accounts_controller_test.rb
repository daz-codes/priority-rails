require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "can change name without a password" do
    patch account_url, params: { user: { name: "Daz" } }

    assert_response :redirect
    assert_equal "Daz", @user.reload.name
  end

  test "changing email requires the current password" do
    patch account_url, params: { user: { email_address: "new@example.com" } }

    assert_response :unprocessable_entity
    assert_match "Current password is required to change your email address", response.body
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "changing email with a wrong password fails" do
    patch account_url, params: { user: { email_address: "new@example.com", current_password: "wrong" } }

    assert_response :unprocessable_entity
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "changing email with the current password succeeds" do
    patch account_url, params: { user: { email_address: "new@example.com", current_password: "password" } }

    assert_response :redirect
    assert_equal "new@example.com", @user.reload.email_address
  end
end
