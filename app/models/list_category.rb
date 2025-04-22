class ListCategory < ApplicationRecord
  belongs_to :list
  belongs_to :category

  validates :category_id, uniqueness: { scope: :list_id }
end
