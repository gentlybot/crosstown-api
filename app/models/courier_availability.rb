class CourierAvailability < ApplicationRecord
  belongs_to :courier

  validates :availability_date, presence: true, uniqueness: { scope: :courier_id }

  scope :on, ->(date) { where(availability_date: date) }
  scope :between, ->(from, to) { where(availability_date: from..to) }
end
