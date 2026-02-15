class CategoriesController < ApplicationController
  before_action :set_list
  before_action :set_category, only: [ :update, :destroy ]

  COLORS = %w[#fca5a5 #fdba74 #fef08a #d9f99d #a5f3fc #93c5fd #c4b5fd #f9a8d4].freeze

  def create
    category = Category.find_or_create_by!(name: params[:name].strip) do |c|
      c.color = COLORS.first
    end
    @list.categories << category unless @list.categories.include?(category)
    redirect_to edit_list_path(@list)
  end

  def update
    @category.update!(category_params)
    redirect_to edit_list_path(@list)
  end

  def destroy
    fallback = @list.categories.where.not(id: @category.id).first
    @list.tasks.where(category_id: @category.id).update_all(category_id: fallback&.id)
    @list.categories.delete(@category)

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

  def category_params
    params.expect(category: [ :name, :color ])
  end
end
