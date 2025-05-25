class ListsController < ApplicationController
  before_action :set_list, only: %i[ show edit update destroy snoozed ]

  def index
    @lists = Current.user.lists
  end

  def show
    @task = Task.new
    @tasks, @title = case params[:list]
              when "priority"
                [ @list.tasks.priority, "PR!OR!TY!" ]
              when "completed"
                [ @list.tasks.completed, "Completed Tasks" ]
              when "today"
                [ @list.tasks.completed_today, "Completed Today" ]
              when "snoozed"
                [ @list.tasks.snoozed, "Snoozed Tasks" ]
              else
                [ @list.tasks.active, nil ]
              end
  end

  def snoozed
    @task = Task.new
    @tasks = @list.tasks.snoozed
    render :show
  end

  def new
    @list = List.new
  end

  def create
    @list = Current.user.lists.new(list_params)
    if @list.save
      redirect_to @list, notice: "List was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @list.update(list_params)
      redirect_to @list, notice: "List was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @list.destroy!
    redirect_to lists_path, status: :see_other, notice: "List was successfully destroyed."
  end

  private
    def set_list
      @list = Current.user.lists.find(params.expect(:id))
      redirect_to root_path unless @list
    end

    def list_params
      params.expect(list: [ :name ])
    end
end
