class Courier < ApplicationRecord
  belongs_to :user
  has_many :route_offers, dependent: :destroy
  has_many :routes, dependent: :nullify
  has_many :courier_availabilities, dependent: :destroy

  STATUSES = %w[active paused].freeze
  enum :status, STATUSES.index_by(&:itself), default: "active"

  VEHICLES = %w[car van bike].freeze
  validates :vehicle_type, inclusion: { in: VEHICLES }

  delegate :name, :email, to: :user

  scope :available_on, ->(date) { active.joins(:courier_availabilities).merge(CourierAvailability.on(date)) }

  def available_on?(date)
    active? && courier_availabilities.on(date).exists?
  end
end
