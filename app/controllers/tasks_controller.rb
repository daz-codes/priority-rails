class TasksController < ApplicationController
  before_action :set_task, only: [ :edit, :update, :destroy, :move ]

  def create
    @list = Current.user.lists.find(params[:list_id])
    @task = @list.tasks.build(task_params)
    @task.apply_category_hashtag
    @task.category ||= @list.category_for_new_tasks

    if @task.save
      redirect_to list_path(@list), flash: { highlight: @task.id }
    else
      redirect_to list_path(@list), alert: @task.errors.full_messages.to_sentence
    end
  end

  def edit = nil

  def update
    source = @task.list
    @task.assign_attributes(task_params)
    # list_id isn't a permitted param; moving only ever targets one of the user's own lists
    @task.assign_list(Current.user.lists.find(params.dig(:task, :list_id))) if params.dig(:task, :list_id).present?

    if @task.save
      if @task.list != source && request.format.turbo_stream?
        render turbo_stream: moved_streams(source)
      elsif request.media_type == Mime[:json].to_s
        # A Helium $patch (checkbox, snooze, recurrence): refresh this tab now. A redirect would be
        # followed as another PATCH, and the broadcast refresh this coincides with is debounced into it.
        render turbo_stream: turbo_stream.refresh(request_id: nil)
      else
        redirect_back fallback_location: source
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def move
    source = @task.list
    destination = Current.user.lists.find(params.expect(:list_id))
    @task.move_to(destination)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: moved_streams(source) }
      format.html { redirect_to list_path(source), status: :see_other }
    end
  end

  def restore
    task = Task.restore(params[:token], lists: Current.user.lists)
    return head :gone unless task

    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ turbo_stream.update("toasts", html: ""), turbo_stream.refresh(request_id: nil) ] }
      format.html { redirect_to task.list, status: :see_other }
    end
  end

  def sort
    ids = Array(params[:task_ids]).map(&:to_i).uniq
    return head :ok if ids.empty?

    tasks = Current.user.tasks.where(id: ids)
    return head :not_found unless tasks.size == ids.size # unknown, or on someone else's list

    list_ids = tasks.map(&:list_id).uniq
    return head :unprocessable_entity unless list_ids.one?

    List.find(list_ids.first).reorder_tasks(ids)
    head :ok
  end

  def destroy
    restore_token = @task.restore_token
    @task.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@task),
          toast("Deleted “#{@task.description}”", undo: { url: restore_tasks_path, method: :post, params: { token: restore_token } })
        ]
      end
      format.html { redirect_back fallback_location: @task.list }
    end
  end

  private

  def set_task
    @task = Current.user.tasks.find(params[:id])
  end

  def task_params
    params.expect(task: [ :description, :position, :category_id, :completed, :completed_on, :snoozed_until, :note, :recurrence_type, :recurrence_day, :recurrence_month ])
  end

  def moved_streams(source)
    [
      turbo_stream.remove(@task),
      toast("Moved to #{@task.list.name}", undo: { url: move_task_path(@task), method: :patch, params: { list_id: source.id } }),
      turbo_stream.refresh(request_id: nil)
    ]
  end

  def toast(message, undo: nil)
    turbo_stream.update("toasts", partial: "toasts/toast", locals: { message: message, undo: undo })
  end
end
