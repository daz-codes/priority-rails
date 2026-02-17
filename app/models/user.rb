class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_and_belongs_to_many :lists
  has_many :tasks, through: :lists

  after_create :accept_pending_invitations

  validates :email_address, presence: true
  validates :password, presence: true, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def name
    self[:name].presence || email_address
  end


  private

  def accept_pending_invitations
    PendingInvitation.where(email: self.email_address).find_each do |invite|
      invite.list.users << self unless invite.list.users.include?(self)
      invite.destroy
    end
  end
end
