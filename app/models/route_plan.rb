# One row per merchant and delivery day, tracking the latest routing run so the
# ops screen can show queued, running, done, or failed without polling Sidekiq.
class RoutePlan < ApplicationRecord
  belongs_to :merchant
  belongs_to :requested_by, class_name: "User", optional: true

  STATUSES = %w[queued running done failed].freeze
  enum :status, STATUSES.index_by(&:itself), default: "queued"

  validates :delivery_date, presence: true, uniqueness: { scope: :merchant_id }

  def building?
    queued? || running?
  end
end
