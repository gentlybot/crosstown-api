class Batch < ApplicationRecord
  belongs_to :merchant
  belongs_to :created_by, class_name: "User", optional: true
  has_many :orders, dependent: :destroy

  STATUSES = %w[importing needs_review ready failed].freeze
  enum :status, STATUSES.index_by(&:itself), default: "importing"

  validates :name, :delivery_date, presence: true

  scope :recent, -> { order(created_at: :desc) }

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
