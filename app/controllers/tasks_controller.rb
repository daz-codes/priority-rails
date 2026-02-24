class TasksController < ApplicationController
  before_action :set_task, only: [ :edit, :update, :destroy ]

  def create
    @list = Current.user.lists.find(params[:list_id])
    @task = @list.tasks.build(task_params)
    @task.category_id ||= default_category_id(@list)

    if @task.save
      redirect_to list_path(@list), flash: { highlight: @task.id }
    else
      render @list, status: :unprocessable_entity
    end
  end

  def edit = nil

  def update
    if @task.update(task_params)
      redirect_back fallback_location: @task.list
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def sort
    Task.transaction do
      params[:task_ids].each_with_index do |id, index|
        Task.find(id).update(position: index + 1)
      end
    end
    head :ok
  end

  def destroy
    @task.destroy!
    redirect_back fallback_location: @task.list
  end

  private

  def set_task
    @task = Current.user.tasks.find(params[:id])
  end

  def task_params
    params.expect(task: [ :description, :list_id, :position, :category_id, :completed, :completed_on, :snoozed_until, :note, :recurrence_type, :recurrence_day, :recurrence_month ])
  end

  def default_category_id(list)
    list.categories.find_by(name: "Work")&.id || list.categories.first&.id
  end
end
