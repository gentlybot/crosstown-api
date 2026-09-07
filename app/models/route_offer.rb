# One courier's chance at one route. Offers go out to every active courier at
# once; the first to accept gets the route and the rest are withdrawn.
class RouteOffer < ApplicationRecord
  belongs_to :route
  belongs_to :courier

  STATUSES = %w[offered accepted declined expired withdrawn].freeze
  enum :status, STATUSES.index_by(&:itself), default: "offered"

  scope :open, -> { offered.where("expires_at > ?", Time.current) }

  def open?
    offered? && expires_at > Time.current
  end
end
