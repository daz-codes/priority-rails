class TasksController < ApplicationController
  before_action :set_task, only: [ :edit, :update, :destroy ]
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
    logger.debug "Current user: #{Current.user.inspect}"
    logger.debug "Task params: #{params[:task].inspect}"

        respond_to do |format|
      if @task.update(task_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@task) }
        format.html { redirect_to @task.list }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def sort
    # Start a transaction to ensure consistency
    Task.transaction do
      params[:task_ids].each_with_index do |id, index|
        task = Task.find(id)  # Finding the task to ensure it's a valid task
        task.update(position: index + 1)  # Use update instead of update_all to trigger callbacks
      end
    end
    
    head :ok  # Respond with a success status
  end

  def destroy
    list = @task.list
    @task.destroy!
    reorder_tasks(list)
  
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@task) }
      format.html { redirect_to @task.list, status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    def task_params
      params.expect(task: [ :description, :list_id, :position, :category, :completed_on, :snoozed_until ])
    end

    def reorder_tasks(list)
      list.tasks.ordered.each_with_index do |task, index|
        task.update(position: index + 1)
      end
    end
end
