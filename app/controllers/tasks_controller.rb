class TasksController < ApplicationController
  before_action :set_task, only: [ :edit, :update, :destroy ]
  DEFAULT_CATEGORY = Category.first&.name || "Work"

  def create
    @list = Current.user.lists.find(params[:list_id])
    @task = @list.tasks.build(task_params)
    @task.category = DEFAULT_CATEGORY

    if @task.save
      redirect_to list_path(@list, highlight: @task.id)
    else
      render @list, status: :unprocessable_entity
    end
  end

  def update
    if params[:task][:completed] == true
      params[:task][:completed_on] = DateTime.current
    elsif params[:task][:completed] == false
      params[:task][:completed_on] = nil
    end
    if @task.update(task_params)
      redirect_to @task.list
    else
      render :edit, status: :unprocessable_entity
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

  def edit_note
    render partial: "tasks/note_form", locals: { task: @task }
  end

  def destroy
    if @task.destroy!
      redirect_to @task.list
    end
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    def task_params
      params.expect(task: [ :description, :list_id, :position, :category, :completed_on, :snoozed_until, :note ])
    end
end
