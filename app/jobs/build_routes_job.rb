class BuildRoutesJob < ApplicationJob
  queue_as :default

  def perform(merchant_id, delivery_date)
    merchant = Merchant.find(merchant_id)
    Routing::Planner.new(merchant, Date.iso8601(delivery_date)).call
  rescue Routing::Planner::Failed, Routing::Engines::VrpCli::SolverError => e
    # The plan row already records the failure for the ops screen.
    Rails.logger.warn("BuildRoutesJob: #{e.class}: #{e.message}")
  end
end
