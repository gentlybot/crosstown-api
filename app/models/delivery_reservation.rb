class DeliveryReservation < ApplicationRecord
  belongs_to :delivery_allowance
  belongs_to :user

  scope :active, -> { where(cancelled_at: nil) }

  validates :period_start, :request_key, presence: true
  validates :request_key, length: { maximum: 120 }, uniqueness: { scope: :user_id }
  validates :units, numericality: { only_integer: true, greater_than: 0 }
  validate :same_merchant

  private

  def same_merchant
    errors.add(:user, "must belong to this merchant") unless user&.merchant_id == delivery_allowance&.merchant_id && user&.merchant_user?
  end
end
