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
    params.expect(user: [ :name, :email_address ])
  end
end
