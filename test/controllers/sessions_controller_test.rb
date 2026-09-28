require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "a failed login shows the alert" do
    post session_url, params: { email_address: "one@example.com", password: "wrong" }
    follow_redirect!

    assert_select "#flash_alert", "Try another email address or password."
  end
end
