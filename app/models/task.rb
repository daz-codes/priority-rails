class Task < ApplicationRecord
  # associations
  belongs_to :list, touch: true
  belongs_to :category, optional: true
  belongs_to :previous_occurrence, class_name: "Task", optional: true
  has_one :next_occurrence, class_name: "Task", foreign_key: :previous_occurrence_id, dependent: :nullify, inverse_of: :previous_occurrence

  # validations
  RECURRENCE_TYPES = %w[daily weekly monthly yearly].freeze
  RESTORE_WINDOW = 10.minutes
  RESTORABLE_ATTRIBUTES = %w[id list_id category_id description position completed_on snoozed_until
                             recurrence_type recurrence_day recurrence_month created_at].freeze

  validates :description, presence: true
  validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }, allow_blank: true
  validates :recurrence_month, inclusion: { in: 1..12 }, allow_nil: true
  validate :category_belongs_to_list

  # position
  positioned on: :list

  # lexxy
  has_rich_text :note

  # broadcasts
  after_destroy_commit -> { broadcast_remove_to list }
  after_update_commit :refresh_list
  after_update_commit :create_next_recurrence
  after_update_commit :remove_next_recurrence

  # scopes
  scope :ordered, -> { order(position: :asc) }
  scope :completed, -> { where.not(completed_on: nil).order(completed_on: :desc) }
  scope :completed_today, -> { where(completed_on: Date.current.all_day).ordered }
  scope :completed_yesterday, -> { where(completed_on: 1.day.ago.all_day).ordered }
  scope :completed_this_week, -> { where(completed_on: 7.days.ago ... 1.day.ago).ordered }
  scope :completed_this_month, -> { where(completed_on: Date.current.beginning_of_month ... 7.days.ago).ordered }
  scope :completed_in_year, ->(year) { where(completed_on: Date.new(year)...Date.new(year + 1)).where("completed_on < ?", Date.current.beginning_of_month).ordered }
  scope :completed_before_today, -> { where("completed_on < ?", Date.current.beginning_of_day).ordered }
  scope :incomplete, -> { where(completed_on: nil).ordered }
  scope :snoozed, -> { where("snoozed_until > ?", Time.current).order(snoozed_until: :asc) }
  scope :unsnoozed, -> { where("snoozed_until IS NULL OR snoozed_until <= ?", Time.current).ordered }
  scope :priority, -> { active.incomplete.ordered.limit(3) }
  scope :active, -> {
    unsnoozed.where(completed_on: nil)
      .or(unsnoozed.where(completed_on: Date.current.all_day))
      .ordered
  }

  def self.restore_verifier = Rails.application.message_verifier(:task_restore)

  # Recreates a deleted task from #restore_token, only into one of the given lists and only once
  def self.restore(token, lists:)
    attributes = restore_verifier.verified(token) or return
    list = lists.find_by(id: attributes["list_id"]) or return
    return unless Rails.cache.write("tasks/restored/#{attributes["id"]}", true, unless_exist: true, expires_in: RESTORE_WINDOW)

    attributes["category_id"] = nil unless list.categories.exists?(attributes["category_id"])
    list.tasks.create!(attributes.except("id", "list_id"))
  end

  def self.completed_years
    where.not(completed_on: nil)
      .where("completed_on < ?", Date.current.beginning_of_month)
      .distinct
      .pluck(Arel.sql("strftime('%Y', completed_on)"))
      .map(&:to_i)
      .sort
      .reverse
  end

  # methods
  def move_to(new_list)
    assign_list(new_list)
    save!
  end

  # Keeps the category when the destination has one with the same name, otherwise uses its default
  def assign_list(new_list)
    return if new_list == list

    self.category = new_list.categories.find_by(name: category&.name) || new_list.categories.first
    self.list = new_list
  end

  def restore_token
    self.class.restore_verifier.generate(
      attributes.slice(*RESTORABLE_ATTRIBUTES).merge("note" => note&.body&.to_html),
      expires_in: RESTORE_WINDOW
    )
  end

  def completed? = completed_on.present?
  def snoozed? = snoozed_until&.future?
  def recurring? = recurrence_type.present?

  def completed=(value)
    self.completed_on = ActiveModel::Type::Boolean.new.cast(value) ? DateTime.current : nil
  end

  def recurrence_label
    return nil unless recurring?

    case recurrence_type
    when "daily"
      "Every day"
    when "weekly"
      day_name = Date::DAYNAMES[recurrence_day || 0]
      "Every #{day_name}"
    when "monthly"
      "Every month on the #{ordinalize(recurrence_day || 1)}"
    when "yearly"
      month_name = Date::MONTHNAMES[recurrence_month || 1]
      "Every year on #{month_name} #{recurrence_day || 1}"
    end
  end

  def next_occurrence_date
    return nil unless recurring?

    today = Date.current
    case recurrence_type
    when "daily"
      today + 1.day
    when "weekly"
      target_wday = recurrence_day || 0
      days_ahead = (target_wday - today.wday) % 7
      days_ahead = 7 if days_ahead == 0
      today + days_ahead.days
    when "monthly"
      target_day = recurrence_day || 1
      candidate = Date.new(today.year, today.month, [ target_day, Time.days_in_month(today.month, today.year) ].min)
      candidate <= today ? candidate.next_month : candidate
    when "yearly"
      target_month = recurrence_month || 1
      target_day = recurrence_day || 1
      candidate = Date.new(today.year, target_month, [ target_day, Time.days_in_month(target_month, today.year) ].min)
      candidate <= today ? Date.new(today.year + 1, target_month, [ target_day, Time.days_in_month(target_month, today.year + 1) ].min) : candidate
    end
  end

  private

  def ordinalize(n)
    suffix = if (11..13).include?(n % 100)
      "th"
    else
      case n % 10
      when 1 then "st"
      when 2 then "nd"
      when 3 then "rd"
      else "th"
      end
    end
    "#{n}#{suffix}"
  end

  def remove_next_recurrence
    return unless saved_change_to_completed_on? && !completed?

    occurrence = reload_next_occurrence
    occurrence.destroy if occurrence && !occurrence.completed?
  end

  def category_belongs_to_list
    return if category.nil? || category.list_id == list_id

    errors.add(:category, "must belong to the same list")
  end

  def refresh_list
    broadcast_remove_to list if saved_change_to_snoozed_until?
  end

  def create_next_recurrence
    return unless recurring? && saved_change_to_completed_on? && completed?
    return if reload_next_occurrence

    list.tasks.create!(
      previous_occurrence: self,
      description: description,
      category_id: category_id,
      note: note&.body&.to_html,
      recurrence_type: recurrence_type,
      recurrence_day: recurrence_day,
      recurrence_month: recurrence_month,
      snoozed_until: next_occurrence_date&.beginning_of_day
    )
  end
end
