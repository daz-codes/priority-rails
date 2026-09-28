require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "prefills the email from an invite link" do
    get new_registration_url(email: "friend@example.com")

    assert_select "input[name='user[email_address]'][value='friend@example.com']"
  end

  test "signing up with a taken email shows an error instead of crashing" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { email_address: users(:one).email_address, password: "password" } }
    end

    assert_response :unprocessable_entity
    assert_match "Email address has already been taken", response.body
  end

  test "signing up accepts pending invitations" do
    invitation = pending_invitations(:one)

    post registration_url, params: { user: { email_address: invitation.email, password: "password" } }

    assert_includes invitation.list.users, User.find_by(email_address: invitation.email)
    assert_not PendingInvitation.exists?(invitation.id)
  end
end
