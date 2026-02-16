class ListsController < ApplicationController
  before_action :set_list, only: %i[ show edit update destroy add_user completed_year ]
  before_action :set_lists, only: %i[ index show ]
  before_action :set_weekly_stats, only: %i[ index ]

  def show
    @task = Task.new
    @filter = params[:list]
    @priority = @filter == "priority"
    @category_ids = Array(params[:category_ids]).map(&:to_i).select(&:positive?)
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
    @tasks = @tasks.where(category_id: @category_ids) if @category_ids.any?
    @completed_years = @list.tasks.completed_years if @filter == "completed"
  end

  def new
    @list = List.new
  end

  def create
    @list = Current.user.lists.new(list_params)
    if @list.save
      Current.user.lists << @list
      respond_to do |format|
        format.html { redirect_to @list, notice: "List was successfully created." }
        format.json { render json: { url: list_url(@list) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @list.errors.full_messages }, status: :unprocessable_entity }
      end
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

  def completed_year
    @year = params[:year].to_i
    @tasks = @list.tasks.completed_in_year(@year)
    render layout: false
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

    def set_lists
      @lists = Current.user.lists
    end

    def set_weekly_stats
      @completed_this_week = Current.user.tasks.completed_this_week.count
    end

    def list_params
      params.expect(list: [ :name ])
    end
end
