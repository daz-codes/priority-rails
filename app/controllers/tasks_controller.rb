class TasksController < ApplicationController
  before_action :set_task, only: [ :edit, :update, :destroy, :snooze ]
  DEFAULT_CATEGORY = Category.first&.name || "Work"

  def edit
  end

  def create
    @list = Current.user.lists.find(params[:list_id])
    @task = @list.tasks.build(task_params)
    @task.category = DEFAULT_CATEGORY

    respond_to do |format|
      if @task.save
        format.html { redirect_to @list }
      else
        format.html { render @list, status: :unprocessable_entity }
      end
    end
  end

  def update
    if params[:task][:completed] == true
      params[:task][:completed_on] = DateTime.current
    elsif params[:task][:completed] == false
      params[:task][:completed_on] = nil
    end
    respond_to do |format|
      if @task.update(task_params)
        # format.turbo_stream { render turbo_stream: turbo_stream.replace(@task) }
        format.html { redirect_to @task.list }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def sort
    Task.transaction do
      params[:task_ids].each_with_index do |id, index|
        task = Task.find(id)
        task.update(position: index + 1)  # Use update instead of update_all to trigger callbacks
      end
    end
    head :ok
  end

  def snooze
    if @task.update!(snoozed_until: @task.snoozed? ? nil : 1.day.from_now)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@task) }
        format.html { redirect_to @task.list }
      end
    end
  end

  def destroy
    if @task.destroy!
      respond_to do |format|
        format.html { redirect_to @task.list }
      end
    end
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    def task_params
      params.expect(task: [ :description, :list_id, :position, :category, :completed_on, :snoozed_until ])
    end
end
