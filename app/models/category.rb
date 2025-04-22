class Category < ApplicationRecord
    has_many :list_categories, dependent: :destroy
end
