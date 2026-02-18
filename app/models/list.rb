class List < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :tasks, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :pending_invitations, dependent: :destroy
  validates :name, presence: true
  validates :completed_display, inclusion: { in: %w[never 1_day 3_days 1_week forever] }
  after_create :assign_default_categories

  broadcasts_refreshes

  COMPLETED_DISPLAY_OPTIONS = [
    [ "Never",   "never" ],
    [ "1 day",   "1_day" ],
    [ "3 days",  "3_days" ],
    [ "1 week",  "1_week" ],
    [ "Forever", "forever" ]
  ].freeze

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
    [ { name: "Home", color: "#a5f3fc" },
      { name: "Work", color: "#93c5fd" },
      { name: "Hobbies", color: "#d9f99d" } ].each do |attrs|
      categories.create!(attrs)
    end
  end
end
