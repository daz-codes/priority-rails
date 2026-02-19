class Task < ApplicationRecord
  #associations
  belongs_to :list, touch: true
  belongs_to :category, optional: true

  # validations
  validates :description, presence: true

  # position
  positioned on: :list

  # lexxy
  has_rich_text :note

  # broadcasts
  after_destroy_commit -> { broadcast_remove_to list }
  after_update_commit :refresh_list
  after_update_commit :create_next_recurrence

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

  def refresh_list
    broadcast_remove_to list if saved_change_to_snoozed_until?
  end

  def create_next_recurrence
    return unless recurring? && saved_change_to_completed_on? && completed?

    list.tasks.create!(
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
