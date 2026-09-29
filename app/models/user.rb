class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_and_belongs_to_many :lists
  has_many :owned_lists, class_name: "List", foreign_key: :owner_id, inverse_of: :owner, dependent: :nullify
  has_many :tasks, through: :lists

  after_create :accept_pending_invitations

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :create
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def name
    self[:name].presence || email_address
  end

  def sign_out_other_sessions(except:)
    sessions.where.not(id: except).destroy_all
  end

  def incomplete_task_counts
    tasks.where(completed_on: nil).group(:list_id).count
  end

  private

  def accept_pending_invitations
    PendingInvitation.where(email: self.email_address).find_each do |invite|
      invite.list.users << self unless invite.list.users.include?(self)
      invite.destroy
    end
  end
end
