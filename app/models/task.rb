class Task < ApplicationRecord
  #associations
  belongs_to :list, touch: true

  # validations
  validates :description, presence: true

  # acts as list
  acts_as_list scope: :list
  after_update_commit :broadcast_position_change

  # scopes
  scope :ordered, -> { order(position: :asc) }
  scope :completed, -> { where.not(completed_on: nil).ordered }
  scope :incomplete, -> { where(completed_on: nil).ordered }
  scope :snoozed, -> { where.not(snoozed_until: nil).ordered }
  scope :active, -> { where(snoozed_until: nil).ordered }
  scope :priority, -> { active.incomplete.ordered.limit(3) }

  # methods
  def completed?
    completed_on.present?
  end

  private

  def broadcast_position_change
    broadcast_replace_later_to list
  end
end
