class RouteStop < ApplicationRecord
  belongs_to :route, inverse_of: :route_stops
  belongs_to :order

  STATUSES = %w[pending delivered failed].freeze
  enum :status, STATUSES.index_by(&:itself), default: "pending"

  FAILURE_REASONS = %w[no_answer wrong_address refused unsafe_to_leave other].freeze

  validates :position, presence: true, uniqueness: { scope: :route_id }
  validates :failure_reason, inclusion: { in: FAILURE_REASONS }, allow_nil: true

  def settled?
    delivered? || failed?
  end
end
