class StaffDeliveryLimit < ApplicationRecord
  belongs_to :delivery_allowance
  belongs_to :user

  validates :user_id, uniqueness: { scope: :delivery_allowance_id }
  validates :monthly_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :same_merchant

  private

  def same_merchant
    errors.add(:user, "must belong to this merchant") unless user&.merchant_id == delivery_allowance&.merchant_id && user&.merchant_user?
  end
end
