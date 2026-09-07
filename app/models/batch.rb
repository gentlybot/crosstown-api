class Batch < ApplicationRecord
  belongs_to :merchant
  belongs_to :created_by, class_name: "User", optional: true
  has_many :orders, dependent: :destroy

  STATUSES = %w[importing needs_review ready routed failed].freeze
  enum :status, STATUSES.index_by(&:itself), default: "importing"

  validates :name, :delivery_date, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Called after routing changes. A batch is "routed" once every deliverable row
  # is on a route and nothing is flagged; flagged rows keep it in review.
  def refresh_routing_status!
    routed = orders.routed.count
    unrouted_ready = orders.ready.count
    new_status =
      if problem_count.positive? then "needs_review"
      elsif routed.positive? && unrouted_ready.zero? then "routed"
      else "ready"
      end
    update!(routed_count: routed, status: new_status)
  end

  # Recomputes the counters from the rows and settles the status.
  def finish_import!
    problems = orders.problem.count
    total = orders.count
    update!(
      row_count: total,
      problem_count: problems,
      ready_count: total - problems,
      status: problems.positive? ? "needs_review" : "ready",
      imported_at: Time.current
    )
  end
end
