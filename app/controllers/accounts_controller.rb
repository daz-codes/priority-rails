class AccountsController < ApplicationController
  helper_method :active_sessions

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    # Check against the stored password before assigning, as assigning a new password replaces the digest
    password_confirmed = @user.authenticate(params.dig(:user, :current_password).to_s)
    @user.assign_attributes(account_params)
    changing_password = account_params[:password].present?

    if (@user.email_address_changed? || changing_password) && !password_confirmed
      @user.errors.add(:current_password, "is required to change your email address or password")
      render :edit, status: :unprocessable_entity
    elsif @user.save
      @user.sign_out_other_sessions(except: Current.session) if changing_password
      redirect_to @user.last_list_id? ? list_path(@user.last_list_id) : root_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def active_sessions
    Current.user.sessions.active.recent_first
  end

  def account_params
    params.require(:user).permit(:name, :email_address, :time_zone, :notify_on_list_activity, :notify_on_list_invites, :password, :password_confirmation)
  end
end
