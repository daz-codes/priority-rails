class Category < ApplicationRecord
  belongs_to :list

  validates :name, presence: true, uniqueness: { scope: :list_id }
  validates :color, format: { with: /\A#\h{6}\z/ }
end
