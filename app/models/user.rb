class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_and_belongs_to_many :lists
  has_many :owned_lists, class_name: "List", foreign_key: :owner_id, inverse_of: :owner, dependent: :nullify
  has_many :tasks, through: :lists

  after_create :accept_pending_invitations

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :create
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :time_zone_is_known

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :time_zone, with: ->(zone) { zone.presence } # "Not set" on the profile means nil

  def name
    self[:name].presence || email_address
  end

  def sign_out_other_sessions(except:)
    sessions.where.not(id: except).destroy_all
  end

  # The Rails name for a browser (IANA) time zone, e.g. "Europe/London" -> "London". Where several
  # Rails names share a zone, the one matching its city wins; zones with no Rails name are kept as is.
  def self.time_zone_from_browser(iana_name)
    return unless ActiveSupport::TimeZone[iana_name.to_s]

    names = ActiveSupport::TimeZone::MAPPING.select { |_, iana| iana == iana_name }.keys
    city = iana_name.split("/").last.tr("_", " ")
    names.find { |name| name == city } || names.first || iana_name
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

  def time_zone_is_known
    errors.add(:time_zone, "isn't a known time zone") if time_zone.present? && ActiveSupport::TimeZone[time_zone].nil?
  end
end
