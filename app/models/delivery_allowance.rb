class DeliveryAllowance < ApplicationRecord
  belongs_to :merchant
  has_many :staff_delivery_limits, dependent: :destroy
  has_many :delivery_reservations, dependent: :destroy

  validates :service_type, inclusion: { in: DeliveryAllowances::Catalog::SERVICES.keys }, uniqueness: { scope: :merchant_id }
  validates :monthly_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
