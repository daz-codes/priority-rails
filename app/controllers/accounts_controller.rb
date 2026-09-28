class AccountsController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    @user.assign_attributes(account_params)

    if @user.email_address_changed? && !@user.authenticate(params.dig(:user, :current_password).to_s)
      @user.errors.add(:current_password, "is required to change your email address")
      render :edit, status: :unprocessable_entity
    elsif @user.save
      redirect_to @user.last_list_id? ? list_path(@user.last_list_id) : root_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(:name, :email_address, :fat_finger_mode)
  end
end
