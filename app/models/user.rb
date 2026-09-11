class User < ApplicationRecord
  has_secure_password

  belongs_to :merchant, optional: true
  has_one :courier, dependent: :destroy
  has_many :staff_delivery_limits, dependent: :destroy
  has_many :delivery_reservations, dependent: :destroy

  ROLES = %w[merchant_admin merchant_staff admin courier].freeze
  enum :role, ROLES.index_by(&:itself), default: "merchant_staff"

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :merchant, presence: true, if: :merchant_user?

  def merchant_user?
    merchant_admin? || merchant_staff?
  end
end
