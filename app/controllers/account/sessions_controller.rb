class Account::SessionsController < ApplicationController
  def destroy
    other_sessions.find(params[:id]).destroy
    redirect_to edit_account_path, status: :see_other
  end

  def destroy_others
    Current.user.sign_out_other_sessions(except: Current.session)
    redirect_to edit_account_path, status: :see_other
  end

  private

  def other_sessions
    Current.user.sessions.where.not(id: Current.session.id)
  end
end
