class List < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :tasks, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :pending_invitations, dependent: :destroy
  validates :name, presence: true
  after_create :assign_default_categories

  broadcasts_refreshes

  private

  def assign_default_categories
    [ { name: "Home", color: "#a5f3fc" },
      { name: "Work", color: "#93c5fd" },
      { name: "Hobbies", color: "#d9f99d" } ].each do |attrs|
      categories.create!(attrs)
    end
  end
end
