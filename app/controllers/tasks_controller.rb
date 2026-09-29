class TasksController < ApplicationController
  before_action :set_task, only: [ :edit, :update, :destroy, :move ]

  def create
    @list = Current.user.lists.find(params[:list_id])
    @task = @list.tasks.build(task_params)
    @task.category_id ||= default_category_id(@list)

    if @task.save
      redirect_to list_path(@list), flash: { highlight: @task.id }
    else
      redirect_to list_path(@list), alert: @task.errors.full_messages.to_sentence
    end
  end

  def edit = nil

  def update
    if @task.update(task_params)
      if request.format.turbo_stream? && @task.saved_change_to_completed_on?
        render turbo_stream: completion_streams
      else
        redirect_back fallback_location: @task.list
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
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@task),
          toast("Moved to #{destination.name}", undo: { url: move_task_path(@task), method: :patch, params: { list_id: source.id } }),
          turbo_stream.refresh(request_id: nil)
        ]
      end
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
    Task.transaction do
      Array(params[:task_ids]).each_with_index do |id, index|
        Current.user.tasks.find(id).update(position: index + 1)
      end
    end
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

  # The broadcast refresh that follows a completion re-renders the list, so only the toast is needed here.
  # Undoing comes from a Turbo form, whose own broadcast Turbo ignores, so that path refreshes explicitly.
  def completion_streams
    if @task.completed?
      toast("Completed “#{@task.description}”", undo: { url: task_path(@task), method: :patch, params: { task: { completed: false } } })
    else
      [ turbo_stream.update("toasts", html: ""), turbo_stream.refresh(request_id: nil) ]
    end
  end

  def toast(message, undo: nil)
    turbo_stream.update("toasts", partial: "toasts/toast", locals: { message: message, undo: undo })
  end

  def default_category_id(list)
    list.categories.find_by(name: "Work")&.id || list.categories.first&.id
  end
end
