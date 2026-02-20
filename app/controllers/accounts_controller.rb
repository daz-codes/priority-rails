class AccountsController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    if @user.update(account_params)
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
