class CategoriesController < ApplicationController
  before_action :set_list
  # Categories are added, renamed and recoloured with the rest of the list's settings (ListsController#update)
  before_action :set_category, only: :destroy

  def sort
    ids = Array(params[:category_ids]).map(&:to_i).uniq
    return head :unprocessable_entity unless ids.sort == @list.categories.ids.sort # exactly this list's categories

    @list.reorder_categories(ids)
    head :ok
  end

  def destroy
    # Its tasks move to the default: the first of the remaining categories
    fallback = @list.categories.where.not(id: @category.id).first
    @list.tasks.where(category_id: @category.id).update_all(category_id: fallback&.id)
    @category.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@category) }
      format.html { redirect_to edit_list_path(@list) }
    end
  end

  private

  def set_list
    @list = Current.user.lists.find(params[:list_id])
  end

  def set_category
    @category = @list.categories.find(params[:id])
  end
end
