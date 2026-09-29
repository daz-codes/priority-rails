class SearchesController < ApplicationController
  RESULT_LIMIT = 50

  def show
    @query = params[:q].to_s.strip
    return if @query.length < 2

    pattern = "%#{Task.sanitize_sql_like(@query)}%"
    @lists = Current.user.lists.where("lists.name LIKE ? ESCAPE '\\'", pattern).order(:name)
    @tasks = Task.where(list: Current.user.lists)
      .left_joins(:rich_text_note)
      .where("tasks.description LIKE :pattern ESCAPE '\\' OR action_text_rich_texts.body LIKE :pattern ESCAPE '\\'", pattern: pattern)
      .includes(:list, :category)
      .order(Arel.sql("tasks.completed_on IS NOT NULL"), updated_at: :desc)
      .limit(RESULT_LIMIT)
  end
end
