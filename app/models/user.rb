class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_and_belongs_to_many :lists
  has_many :tasks, through: :lists

  after_create :accept_pending_invitations

  validates :email_address, :password, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def name = email_address


  private

  def accept_pending_invitations
    PendingInvitation.where(email: self.email.downcase).find_each do |invite|
      invite.list.users << self unless invite.list.users.include?(self)
      invite.destroy
    end
  end
end
