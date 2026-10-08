class List < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_and_belongs_to_many :users
  has_many :tasks, dependent: :destroy
  has_many :categories, -> { order(:position, :id) }, dependent: :destroy
  has_many :pending_invitations, dependent: :destroy
  validates :name, presence: true
  validates :completed_display, inclusion: { in: %w[never 1_day 3_days 1_week forever] }
  after_create :assign_default_categories, unless: :copying
  # Lists should always have an owner; one that's lost it takes its longest-standing member
  before_validation(if: -> { persisted? && owner_id.nil? }) { self.owner = users.order(:id).first }

  # Set while duplicating, so the copy gets the original's categories rather than the defaults
  attr_accessor :copying

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  broadcasts_refreshes

  COMPLETED_DISPLAY_OPTIONS = [
    [ "Never",   "never" ],
    [ "1 day",   "1_day" ],
    [ "3 days",  "3_days" ],
    [ "1 week",  "1_week" ],
    [ "Forever", "forever" ]
  ].freeze

  # An ownerless list can be managed by any member rather than by nobody
  def owned_by?(user) = owner_id ? owner_id == user.id : users.include?(user)
  def archived? = archived_at.present?
  def archive! = update!(archived_at: Time.current)
  def unarchive! = update!(archived_at: nil)

  # A fresh copy for `owner` alone, e.g. to reuse a packing list or weekly routine: same categories
  # (and default), settings, and tasks with their notes and recurrence, but every task starts again
  # (not completed, not snoozed). Completed occurrences of a recurring task aren't copied, only the
  # latest, so each recurring task appears once.
  def duplicate(name:, owner:)
    transaction do
      copy = owner.lists.create!(name: name, owner: owner, focus_limit: focus_limit, completed_display: completed_display, copying: true)

      # Created in order, so the copy's first category (its default) matches
      category_copies = categories.to_h { |category| [ category.id, copy.categories.create!(name: category.name, color: category.color) ] }

      tasks.ordered.includes(:rich_text_note, :next_occurrence).reject(&:next_occurrence).each do |task|
        copy.tasks.create!(
          description: task.description,
          category: category_copies[task.category_id],
          note: task.note&.body&.to_html,
          recurrence_type: task.recurrence_type,
          recurrence_day: task.recurrence_day,
          recurrence_month: task.recurrence_month,
          recurrence_interval: task.recurrence_interval
        )
      end
      copy
    end
  end

  # The category new tasks get when none is given: the first one (drag to reorder in settings)
  def category_for_new_tasks = categories.first

  # Reorders just the given tasks within the positions they already hold, so tasks that weren't on
  # screen (filtered by category, snoozed, older completed ones) keep their place. Dragging B3 above
  # B2 in a filtered A1 B2 B3 B4 A5 B6 gives A1 B3 B2 B4 A5 B6.
  def reorder_tasks(ids)
    transaction do
      slots = tasks.where(id: ids).order(:position).pluck(:position)
      ids.zip(slots).each { |id, position| tasks.where(id: id).update_all(position: position) }
      touch # broadcasts the new order to anyone else viewing the list
    end
  end

  # Sets the order of this list's categories (from dragging them in settings)
  def reorder_categories(ids)
    transaction do
      ids.each.with_index(1) { |id, position| categories.where(id: id).update_all(position: position) }
      touch # broadcasts the new order
    end
  end

  def active_tasks
    base = tasks.unsnoozed.where(completed_on: nil).ordered
    return base if completed_display == "never"

    completed = case completed_display
    when "1_day"  then tasks.unsnoozed.where(completed_on: Date.current.all_day)
    when "3_days" then tasks.unsnoozed.where(completed_on: 2.days.ago.beginning_of_day..)
    when "1_week" then tasks.unsnoozed.where(completed_on: 6.days.ago.beginning_of_day..)
    when "forever" then tasks.unsnoozed.where.not(completed_on: nil)
    end
    base.or(completed.ordered)
  end

  private

  def assign_default_categories
    # Work first, so it's the default as it always has been
    [ { name: "Work", color: "#93c5fd" },
      { name: "Home", color: "#a5f3fc" },
      { name: "Hobbies", color: "#d9f99d" } ].each do |attrs|
      categories.create!(attrs)
    end
  end
end
