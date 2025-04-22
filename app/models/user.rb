class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :lists, dependent: :destroy
  has_many :tasks, through: :lists

  validates :email_address, :password, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def name
    email_address
  end
end
