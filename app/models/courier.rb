class Courier < ApplicationRecord
  belongs_to :user
  has_many :route_offers, dependent: :destroy
  has_many :routes, dependent: :nullify

  STATUSES = %w[active paused].freeze
  enum :status, STATUSES.index_by(&:itself), default: "active"

  VEHICLES = %w[car van bike].freeze
  validates :vehicle_type, inclusion: { in: VEHICLES }

  delegate :name, :email, to: :user
end
