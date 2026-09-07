class User < ApplicationRecord
  has_secure_password

  belongs_to :merchant, optional: true

  ROLES = %w[merchant_admin merchant_staff admin].freeze
  enum :role, ROLES.index_by(&:itself), default: "merchant_staff"

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :merchant, presence: true, unless: :admin?

  def merchant_user?
    merchant_admin? || merchant_staff?
  end
end
