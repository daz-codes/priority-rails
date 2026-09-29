class Category < ApplicationRecord
  belongs_to :list

  validates :name, presence: true, uniqueness: { scope: :list_id }
  validates :color, format: { with: /\A#\h{6}\z/ }

  # "Side project", "#side-project" and "#SideProject" all reduce to "sideproject"
  def self.hashtag_key(text) = text.to_s.downcase.gsub(/[^[:alnum:]]/, "")
end
