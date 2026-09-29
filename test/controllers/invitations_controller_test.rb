require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = lists(:one)
    @invitation = pending_invitations(:one)
    sign_in_as users(:one)
  end

  test "any member can cancel an invite" do
    delete list_invitation_url(@list, @invitation)

    assert_redirected_to edit_list_url(@list)
    assert_not PendingInvitation.exists?(@invitation.id)
  end

  test "resending emails the invitee again" do
    assert_enqueued_email_with InviteMailer, :invite, params: { email: @invitation.email, list: @list } do
      post resend_list_invitation_url(@list, @invitation)
    end

    assert_redirected_to edit_list_url(@list)
  end

  test "cannot touch invites on someone else's list" do
    delete list_invitation_url(lists(:two), pending_invitations(:two))

    assert_response :not_found
    assert PendingInvitation.exists?(pending_invitations(:two).id)
  end

  test "settings page shows resend and cancel for pending invites" do
    get edit_list_url(@list)

    assert_select "##{ActionView::RecordIdentifier.dom_id(@invitation)} button", text: "Resend"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@invitation)} button[title='Cancel invite']"
  end
end
