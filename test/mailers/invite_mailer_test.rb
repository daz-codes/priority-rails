require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "invite links to sign up with the invited email" do
    list = lists(:one)
    mail = InviteMailer.with(email: "friend@example.com", list: list).invite

    assert_equal [ "friend@example.com" ], mail.to
    assert_equal [ "no-reply@priority-list.app" ], mail.from
    assert_match list.name, mail.text_part.body.to_s
    assert_match "/registration/new?email=friend%40example.com", mail.text_part.body.to_s
  end
end
