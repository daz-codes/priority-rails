class List < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy
  has_many :list_categories, dependent: :destroy
  has_many :categories, through: :list_categories
  validates :name, presence: true
  after_create :assign_default_categories

  after_create_commit  -> { broadcast_refresh_later_to(model_name.plural) }
  after_update_commit  -> { broadcast_refresh_later }

  private
  def assign_default_categories
    default_categories = Category.where(name: ["Home", "Work", "Hobbies"])
    self.categories << default_categories
  end
end
