module RoutePlanSerializer
  def self.call(plan)
    return nil unless plan
    {
      status: plan.status,
      engine: plan.engine,
      routes_count: plan.routes_count,
      stops_count: plan.stops_count,
      unassigned_count: plan.unassigned_count,
      error: plan.error,
      started_at: plan.started_at&.iso8601,
      finished_at: plan.finished_at&.iso8601,
      requested_by: plan.requested_by&.name
    }
  end
end
