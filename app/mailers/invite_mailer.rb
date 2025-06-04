class InviteMailer < ApplicationMailer
  def invite
    @list = params[:list]
    @signup_url = new_user_registration_url(email: params[:email])

    mail(to: params[:email], subject: "You’ve been invited to collaborate on a list")
  end
end
