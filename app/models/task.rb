class Task < ApplicationRecord
  # associations
  belongs_to :list, touch: true
  belongs_to :category, optional: true
  belongs_to :previous_occurrence, class_name: "Task", optional: true
  has_one :next_occurrence, class_name: "Task", foreign_key: :previous_occurrence_id, dependent: :nullify, inverse_of: :previous_occurrence

  # validations
  RECURRENCE_TYPES = %w[daily weekdays weekly monthly yearly].freeze
  # A #tag at the start of the text or after whitespace, so "C#" and "issue#42" are left alone
  HASHTAG = /(?<!\S)#([[:alnum:]_-]+)/
  RESTORE_WINDOW = 10.minutes
  RESTORABLE_ATTRIBUTES = %w[id list_id category_id description position completed_on snoozed_until
                             recurrence_type recurrence_day recurrence_month recurrence_interval created_at].freeze

  validates :description, presence: true
  validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }, allow_blank: true
  validates :recurrence_month, inclusion: { in: 1..12 }, allow_nil: true
  validates :recurrence_interval, inclusion: { in: 1..12 }
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
  # Completed tasks are grouped by calendar day in the user's time zone, each in exactly one section:
  # today, yesterday, the rest of the last seven days, the rest of this month, then by year.
  scope :completed_today, -> { where(completed_on: Date.current.all_day).ordered }
  scope :completed_yesterday, -> { where(completed_on: Date.yesterday.all_day).ordered }
  scope :completed_this_week, -> { where(completed_on: week_start...Date.yesterday.beginning_of_day).ordered }
  scope :completed_this_month, -> { where(completed_on: Date.current.beginning_of_month.beginning_of_day...week_start).ordered }
  scope :completed_in_year, ->(year) { where(completed_on: Time.zone.local(year)...[ Time.zone.local(year + 1), older_than ].min).ordered }
  scope :completed_in_last_seven_days, -> { where(completed_on: week_start..) }
  scope :incomplete, -> { where(completed_on: nil).ordered }
  scope :snoozed, -> { where("snoozed_until > ?", Time.current).order(snoozed_until: :asc) }
  scope :unsnoozed, -> { where("snoozed_until IS NULL OR snoozed_until <= ?", Time.current).ordered }
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

  # Start of the seven-day window (today and the six days before it)
  def self.week_start = (Date.current - 6).beginning_of_day

  # Completions before this belong to the year sections rather than this week or this month
  def self.older_than = [ week_start, Date.current.beginning_of_month.beginning_of_day ].min

  # Years are worked out in the user's time zone, so a New Year's Eve evening isn't filed under the next year
  def self.completed_years
    where(completed_on: ...older_than).pluck(:completed_on).map { |at| at.in_time_zone.year }.uniq.sort.reverse
  end

  # methods
  # Quick-add: "Buy milk #home" files the task under the list's Home category and drops the tag.
  # Tags that don't match a category are left in the text.
  def apply_category_hashtag
    categories = list.categories.index_by { |category| Category.hashtag_key(category.name) }

    description.to_s.scan(HASHTAG).flatten.each do |tag|
      next unless (category = categories[Category.hashtag_key(tag)])

      self.category = category
      self.description = description.sub(/(?<!\S)##{Regexp.escape(tag)}(?!\S)/, "").squish
      break
    end
  end

  # Quick-add: "Get milk every monday" makes the task recur every Monday and drops the phrase. The
  # first occurrence waits for its day: added on a Wednesday, it's snoozed until Monday.
  def apply_recurrence_phrase
    text, rule = RecurrencePhrase.extract(description)
    return if rule.nil? || text.blank?

    self.description = text
    self.recurrence_type, self.recurrence_day, self.recurrence_month, self.recurrence_interval = rule.type, rule.day, rule.month, rule.interval
    first = occurs_on?(Date.current) ? Date.current : next_occurrence_date
    self.snoozed_until = first.beginning_of_day if first > Date.current
  end

  # "Not this time": moves a recurring task on to its next occurrence, keeping the series
  def skip!
    update!(snoozed_until: next_occurrence_date.beginning_of_day) if recurring?
  end

  def move_to(new_list)
    assign_list(new_list)
    save!
  end

  # Keeps the category when the destination has one with the same name, otherwise uses its default
  def assign_list(new_list)
    return if new_list == list

    self.category = new_list.categories.find_by(name: category&.name) || new_list.category_for_new_tasks
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
    self.completed_on = ActiveModel::Type::Boolean.new.cast(value) ? Time.current : nil
  end

  def recurrence_label
    return nil unless recurring?

    every = recurrence_interval.to_i > 1 ? "Every other" : "Every"
    case recurrence_type
    when "daily"
      "#{every} day"
    when "weekdays"
      "Every weekday"
    when "weekly"
      day_name = Date::DAYNAMES[recurrence_day || 0]
      "#{every} #{day_name}"
    when "monthly"
      "Every month on the #{(recurrence_day || 1).ordinalize}"
    when "yearly"
      month_name = Date::MONTHNAMES[recurrence_month || 1]
      "Every year on #{month_name} #{recurrence_day || 1}"
    end
  end

  # Whether the recurrence rule falls on `date` (a 31st falls on the last day of shorter months)
  def occurs_on?(date)
    clamp = ->(day, month, year) { [ day || 1, Time.days_in_month(month, year) ].min }
    case recurrence_type
    when "daily" then true
    when "weekdays" then date.on_weekday?
    when "weekly" then date.wday == (recurrence_day || 0)
    when "monthly" then date.day == clamp.(recurrence_day, date.month, date.year)
    when "yearly" then date.month == (recurrence_month || 1) && date.day == clamp.(recurrence_day, date.month, date.year)
    else false
    end
  end

  def next_occurrence_date
    return nil unless recurring?

    today = Date.current
    interval = [ recurrence_interval.to_i, 1 ].max
    case recurrence_type
    when "daily"
      today + interval.days
    when "weekdays"
      today.next_weekday
    when "weekly"
      target_wday = recurrence_day || 0
      days_ahead = (target_wday - today.wday) % 7
      days_ahead = 7 if days_ahead == 0
      # "Every other": the next one after that, so a week is skipped
      today + (days_ahead + 7 * (interval - 1)).days
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
      recurrence_interval: recurrence_interval,
      snoozed_until: next_occurrence_date&.beginning_of_day
    )
  end
end
