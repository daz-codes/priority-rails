class CategoriesController < ApplicationController
  before_action :set_list
  before_action :set_category, only: [ :update, :destroy, :make_default ]

  COLORS = %w[#fca5a5 #fdba74 #fef08a #d9f99d #a5f3fc #93c5fd #c4b5fd #f9a8d4].freeze

  def create
    category = @list.categories.find_or_create_by(name: params[:name].to_s.strip) do |c|
      c.color = COLORS.first
    end
    redirect_to edit_list_path(@list), alert: category.errors.full_messages.to_sentence.presence
  end

  def update
    @category.update(category_params)
    redirect_to edit_list_path(@list), alert: @category.errors.full_messages.to_sentence.presence
  end

  def sort
    ids = Array(params[:category_ids]).map(&:to_i).uniq
    return head :unprocessable_entity unless ids.sort == @list.categories.ids.sort # exactly this list's categories

    @list.reorder_categories(ids)
    head :ok
  end

  def make_default
    @list.update!(default_category: @category)
    redirect_to edit_list_path(@list), status: :see_other
  end

  def destroy
    others = @list.categories.where.not(id: @category.id)
    fallback = @list.default_category_id == @category.id ? others.first : @list.category_for_new_tasks
    @list.tasks.where(category_id: @category.id).update_all(category_id: fallback&.id)
    default_changed = @list.default_category_id == @category.id
    @list.update!(default_category: fallback) if default_changed
    @category.destroy!

    respond_to do |format|
      format.turbo_stream do
        streams = [ turbo_stream.remove(@category) ]
        streams << turbo_stream.replace(fallback, partial: "categories/category", locals: { list: @list, category: fallback }) if default_changed && fallback
        render turbo_stream: streams
      end
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
