class RouteStop < ApplicationRecord
  belongs_to :route, inverse_of: :route_stops
  belongs_to :order

  validates :position, presence: true, uniqueness: { scope: :route_id }
end
