class RegistrationsController < ApplicationController
    allow_unauthenticated_access
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_url, alert: "Try again later." }

    def new
      @user = User.new(email_address: params[:email])
    end

    def create
      @user = User.new(user_params)

      if @user.save
        start_new_session_for @user
        redirect_to about_path(welcome: true)
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password)
    end
end
