# Preview all emails at http://localhost:3000/rails/mailers/invite_mailer
class InviteMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/invite_mailer/invite
  def invite
    InviteMailer.with(email: "friend@example.com", list: List.take).invite
  end
end
