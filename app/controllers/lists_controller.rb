class ListsController < ApplicationController
  before_action :set_list, only: %i[ show edit update destroy add_user completed_year stats archive unarchive duplicate ]
  before_action :require_owner, only: %i[ archive unarchive ]

  def index
    lists = Current.user.lists.active
    list = (Current.user.last_list_id && lists.find_by(id: Current.user.last_list_id)) || lists.first

    if list
      redirect_to list
    else
      redirect_to new_list_path
    end
  end

  def show
    # Remember the list to reopen on next visit; only show needs this, not stats/settings/etc.
    Current.user.update_column(:last_list_id, @list.id) unless Current.user.last_list_id == @list.id
    @task = Task.new
    @filter = params[:list]
    @priority = @filter == "priority"
    @category_ids = Array(params[:category_ids]).map(&:to_i).select(&:positive?)
    @tasks = case @filter
    when "priority"
                @list.active_tasks.incomplete.ordered.limit(@list.focus_limit)
    when "completed"
                @list.tasks.completed
    when "snoozed"
                @list.tasks.snoozed
    else
                @list.active_tasks
    end
    @tasks = @tasks.where(category_id: @category_ids) if @category_ids.any?
    @tasks = @tasks.includes(:category, :rich_text_note)
    @completed_years = @list.tasks.completed_years if @filter == "completed"
    @done_today = @list.tasks.where(completed_on: Date.current.all_day).count
    @still_to_do = @list.tasks.unsnoozed.where(completed_on: nil).count
  end

  def new
    @list = List.new
  end

  def create
    @list = Current.user.lists.create(list_params.merge(owner: Current.user))
    if @list.persisted?
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
    email = params[:email_address].to_s.strip.downcase
    user = User.find_by(email_address: email)

    if user
      unless @list.users.include?(user)
        @list.users << user
        Notifications.added_to_list(@list, user: user, by: Current.user)
      end
      redirect_to @list, notice: "#{email} has been added to the list."
    elsif (invitation = @list.pending_invitations.find_or_initialize_by(email: email)).save
      InviteMailer.with(email: email, list: @list).invite.deliver_later
      redirect_to @list, notice: "Invitation sent to #{email}."
    else
      redirect_to edit_list_path(@list), alert: invitation.errors.full_messages.to_sentence
    end
  end

  def stats
    @completed_today = @list.tasks.where(completed_on: Date.current.all_day).count
    @completed_last_seven_days = @list.tasks.completed_in_last_seven_days.count
    @completed_all_time = @list.tasks.where.not(completed_on: nil).count
  end

  def completed_year
    @year = params[:year].to_i
    @tasks = @list.tasks.completed_in_year(@year).includes(:category, :rich_text_note)
    render layout: false
  end

  def archived
    @lists = Current.user.lists.archived.order(archived_at: :desc)
  end

  def archive
    @list.archive!
    redirect_to root_path, status: :see_other
  end

  def unarchive
    @list.unarchive!
    redirect_to @list, status: :see_other
  end

  def duplicate
    copy = @list.duplicate(name: params[:name].to_s.strip.presence || "#{@list.name} (copy)", owner: Current.user)
    redirect_to copy, status: :see_other
  end

  def destroy
    return redirect_to(edit_list_path(@list), alert: "Only the list owner can delete it.") unless @list.owned_by?(Current.user)

    @list.destroy!
    redirect_to lists_path, status: :see_other, notice: "List was successfully destroyed."
  end

  private
    def set_list
      @list = Current.user.lists.find(params.expect(:id))
    end

    def require_owner
      redirect_to edit_list_path(@list), alert: "Only the list owner can do that." unless @list.owned_by?(Current.user)
    end

    def list_params
      params.expect(list: [ :name, :focus_limit, :completed_display, categories_attributes: [ [ :id, :name, :color ] ] ])
    end
end
