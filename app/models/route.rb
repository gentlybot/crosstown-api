class Route < ApplicationRecord
  belongs_to :merchant
  belongs_to :courier, optional: true
  has_many :route_stops, -> { order(:position) }, dependent: :destroy, inverse_of: :route
  has_many :orders, through: :route_stops
  has_many :route_offers, dependent: :destroy

  # planned: built, nobody asked yet. offered: couriers can accept. assigned:
  # a courier has it. in_progress: they started. completed: every stop settled.
  STATUSES = %w[planned offered assigned in_progress completed cancelled].freeze
  enum :status, STATUSES.index_by(&:itself), default: "planned"

  FIRST_NUMBER = 200

  before_validation :assign_route_number, on: :create

  validates :delivery_date, :engine, :start_at, :start_lat, :start_lng, presence: true

  def display_name
    "Route #{route_number}"
  end

  def pay_breakdown
    Routing::Pay.breakdown(self)
  end

  def settle_if_finished!
    return unless in_progress? && route_stops.where(status: "pending").none?
    update!(status: "completed", completed_at: Time.current)
  end

  private

  def assign_route_number
    self.route_number ||= [Route.maximum(:route_number).to_i + 1, FIRST_NUMBER].max
  end
end
