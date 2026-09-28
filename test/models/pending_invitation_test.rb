require "test_helper"

class PendingInvitationTest < ActiveSupport::TestCase
  test "normalizes email" do
    assert_equal "friend@example.com", PendingInvitation.new(email: " Friend@Example.com ").email
  end

  test "requires a valid email" do
    assert_not lists(:one).pending_invitations.build(email: "").valid?
    assert_not lists(:one).pending_invitations.build(email: "not-an-email").valid?
  end

  test "email is unique per list" do
    assert_not lists(:one).pending_invitations.build(email: "INVITEE@example.com").valid?
    assert lists(:one).pending_invitations.build(email: "someone-else@example.com").valid?
  end
end
