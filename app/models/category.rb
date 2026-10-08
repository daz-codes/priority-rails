class Category < ApplicationRecord
  belongs_to :list

  before_create { self.position ||= (list.categories.maximum(:position) || 0) + 1 } # new ones go last

  validates :name, presence: true, uniqueness: { scope: :list_id }
  validates :color, format: { with: /\A#\h{6}\z/ }

  # "Side project", "#side-project" and "#SideProject" all reduce to "sideproject"
  def self.hashtag_key(text) = text.to_s.downcase.gsub(/[^[:alnum:]]/, "")
end
