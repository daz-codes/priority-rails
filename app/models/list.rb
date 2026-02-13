class List < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :tasks, dependent: :destroy
  has_many :list_categories, dependent: :destroy
  has_many :pending_invitations, dependent: :destroy
  has_many :categories, through: :list_categories
  validates :name, presence: true
  after_create :assign_default_categories

  broadcasts_refreshes

  private

  def assign_default_categories
    default_categories = Category.where(name: ["Home", "Work", "Hobbies"])
    self.categories << default_categories
  end
end
