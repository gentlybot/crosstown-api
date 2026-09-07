class Route < ApplicationRecord
  belongs_to :merchant
  has_many :route_stops, -> { order(:position) }, dependent: :destroy, inverse_of: :route
  has_many :orders, through: :route_stops

  STATUSES = %w[planned cancelled].freeze
  enum :status, STATUSES.index_by(&:itself), default: "planned"

  FIRST_NUMBER = 200

  before_validation :assign_route_number, on: :create

  validates :delivery_date, :engine, :start_at, :start_lat, :start_lng, presence: true

  def display_name
    "Route #{route_number}"
  end

  private

  def assign_route_number
    self.route_number ||= [Route.maximum(:route_number).to_i + 1, FIRST_NUMBER].max
  end
end
