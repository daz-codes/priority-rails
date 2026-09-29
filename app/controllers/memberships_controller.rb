class MembershipsController < ApplicationController
  before_action :set_list
  before_action :set_member
  before_action :require_owner, only: :transfer

  def destroy
    if @member == Current.user
      leave
    elsif @list.owned_by?(Current.user)
      @list.users.delete(@member)
      redirect_to edit_list_path(@list), status: :see_other
    else
      redirect_to edit_list_path(@list), alert: "Only the list owner can remove members."
    end
  end

  def transfer
    @list.update!(owner: @member)
    redirect_to edit_list_path(@list), status: :see_other
  end

  private

  def set_list
    @list = Current.user.lists.find(params[:list_id])
  end

  def set_member
    @member = @list.users.find(params[:id])
  end

  def require_owner
    redirect_to edit_list_path(@list), alert: "Only the list owner can do that." unless @list.owned_by?(Current.user)
  end

  def leave
    if @list.owned_by?(Current.user)
      redirect_to edit_list_path(@list), alert: "Make someone else the owner before leaving, or delete the list."
    else
      @list.users.delete(Current.user)
      redirect_to root_path, status: :see_other
    end
  end
end
