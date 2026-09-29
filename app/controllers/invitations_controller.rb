class InvitationsController < ApplicationController
  before_action :set_invitation
  rate_limit to: 5, within: 1.hour, only: :resend, by: -> { params[:id] },
    with: -> { redirect_to edit_list_path(@list), alert: "That invite was resent recently. Try again later." }

  def destroy
    @invitation.destroy
    redirect_to edit_list_path(@list), status: :see_other
  end

  def resend
    InviteMailer.with(email: @invitation.email, list: @list).invite.deliver_later
    @invitation.touch
    redirect_to edit_list_path(@list), status: :see_other
  end

  private

  def set_invitation
    @list = Current.user.lists.find(params[:list_id])
    @invitation = @list.pending_invitations.find(params[:id])
  end
end
