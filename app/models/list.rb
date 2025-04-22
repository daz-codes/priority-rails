class List < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy
  has_many :list_categories, dependent: :destroy
  has_many :categories, through: :list_categories
  validates :name, presence: true
  broadcasts_refreshes
  after_create :assign_default_categories

  private
  def assign_default_categories
    default_categories = Category.where(name: ["Home", "Work", "Hobbies"])
    self.categories << default_categories
  end
end
