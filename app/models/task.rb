class Task < ApplicationRecord
  #associations
  belongs_to :list, touch: true

  # validations
  validates :description, presence: true

  # position
  positioned on: :list
  broadcasts_to :list

  # scopes
  scope :ordered, -> { order(position: :asc) }
  scope :completed, -> { where.not(completed_on: nil).ordered }
  scope :completed_today, -> { where(completed_on: Date.current.all_day).ordered }
  scope :completed_before_today, -> { where('completed_on < ?', Date.current.beginning_of_day).ordered }
  scope :incomplete, -> { where(completed_on: nil).ordered }
  scope :snoozed, -> { where("snoozed_until > ?", Time.current).ordered }
  scope :unsnoozed, -> { where("snoozed_until IS NULL OR snoozed_until <= ?", Time.current).ordered }
  scope :priority, -> { active.incomplete.ordered.limit(3) }
  scope :active, -> {
    unsnoozed
      .where(completed_on: nil)
      .or(
        unsnoozed.where(completed_on: Date.current.all_day)
      )
      .ordered
  }

  # methods
  def completed? = completed_on.present?
  def snoozed? = snoozed_until.present? && snoozed_until > Time.current

end
