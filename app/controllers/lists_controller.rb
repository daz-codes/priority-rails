class ListsController < ApplicationController
  before_action :set_list, only: %i[ show edit update destroy add_user ]

  def index
    @lists = Current.user.lists
  end

  def show
    @task = Task.new
    @filter = params[:list]
    @priority = @filter == "priority"
    @tasks = case @filter
              when "priority"
                @list.tasks.priority
              when "completed"
                @list.tasks.completed
              when "snoozed"
                @list.tasks.snoozed
              else
                @list.tasks.active
              end
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

  def add_user
    email = params[:email_address].strip.downcase
    user = User.find_by(email_address: email)

    if user
      @list.users << user unless @list.users.include?(user)
      redirect_to @list, notice: "#{email} has been added to the list."
    else
      PendingInvitation.create!(email: email, list: @list)
      InviteMailer.with(email: email, list: @list).invite.deliver_later
      redirect_to @list, notice: "Invitation sent to #{email}."
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
