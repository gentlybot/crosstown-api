class Order < ApplicationRecord
  belongs_to :batch
  belongs_to :merchant

  STATUSES = %w[pending problem ready].freeze
  enum :status, STATUSES.index_by(&:itself), default: "pending"

  validates :row_number, presence: true, uniqueness: { scope: :batch_id }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  def full_address
    [address_line, unit.presence, city, postal_code].compact.join(", ")
  end
end
