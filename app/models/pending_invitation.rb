class PendingInvitation < ApplicationRecord
  belongs_to :list

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { scope: :list_id }
end
