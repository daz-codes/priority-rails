class Task < ApplicationRecord
  #associations
  belongs_to :list, touch: true

  # validations
  validates :description, presence: true

  # position
  positioned on: :list
  after_update_commit :broadcast_position_change

  # scopes
  scope :ordered, -> { order(position: :asc) }
  scope :completed, -> { where.not(completed_on: nil).ordered }
  scope :incomplete, -> { where(completed_on: nil).ordered }
  scope :snoozed, -> { where("snoozed_until > ?", Time.current).ordered }
  scope :unsnoozed, -> { where("snoozed_until IS NULL OR snoozed_until <= ?", Time.current).ordered }
  scope :active, -> { where(snoozed_until: nil).ordered }
  scope :priority, -> { active.incomplete.ordered.limit(3) }

  # methods
  def completed? = completed_on.present?
  def snoozed? = snoozed_until.present? && snoozed_until > Time.current

  private

  def broadcast_position_change = broadcast_replace_later_to list
end
