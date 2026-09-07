module Routing
  # Builds routes for one merchant and delivery day from every ready, placed
  # order, replacing any planned routes that already exist for that day.
  class Planner
    MAX_STOPS = ENV.fetch("ROUTING_MAX_STOPS", 12).to_i
    SERVICE_MINUTES = 4
    AVERAGE_KMH = 22.0

    class Failed < StandardError; end

    attr_reader :merchant, :delivery_date, :plan

    def initialize(merchant, delivery_date, engine: Engine.default, requested_by: nil)
      @merchant = merchant
      @delivery_date = delivery_date
      @engine = engine
      @plan = RoutePlan.find_or_create_by!(merchant: merchant, delivery_date: delivery_date) do |p|
        p.requested_by = requested_by
      end
    end

    def call
      plan.update!(status: "running", started_at: Time.current, finished_at: nil, error: nil, engine: @engine.name)
      raise Failed, "#{merchant.business_name} has no coordinates for its pickup address." if merchant.pickup_lat.nil? || merchant.pickup_lng.nil?

      routes_built = []
      unassigned = []
      Route.transaction do
        unroute_existing!
        orders = routable_orders.to_a
        if orders.any?
          depot = Point.new(id: "pickup", lat: merchant.pickup_lat, lng: merchant.pickup_lng)
          points = orders.map { |o| Point.new(id: o.id, lat: o.lat, lng: o.lng, service_seconds: SERVICE_MINUTES * 60) }
          solution = @engine.solve(depot: depot, points: points, max_stops: MAX_STOPS, start_at: start_at)
          by_id = orders.index_by(&:id)
          solution.routes.each { |ids| routes_built << build_route(ids.map { |id| by_id.fetch(id) }, depot) }
          unassigned = solution.unassigned
        end
        touched_batches(orders).each(&:refresh_routing_status!)
      end

      plan.update!(
        status: "done",
        finished_at: Time.current,
        routes_count: routes_built.size,
        stops_count: routes_built.sum(&:stop_count),
        unassigned_count: unassigned.size
      )
      routes_built
    rescue StandardError => e
      plan.update!(status: "failed", finished_at: Time.current, error: e.message.truncate(250))
      raise
    end

    private

    def routable_orders
      merchant.orders.joins(:batch)
        .where(batches: { delivery_date: delivery_date })
        .where(status: "ready")
        .where.not(lat: nil, lng: nil)
        .order(:batch_id, :row_number)
    end

    def unroute_existing!
      existing = merchant.routes.where(delivery_date: delivery_date, status: "planned")
      order_ids = RouteStop.where(route_id: existing.select(:id)).pluck(:order_id)
      Order.where(id: order_ids).update_all(status: "ready", updated_at: Time.current)
      existing.destroy_all
      Batch.where(id: Order.where(id: order_ids).select(:batch_id)).find_each(&:refresh_routing_status!)
    end

    def start_at
      hour, minute = merchant.cutoff_time.split(":").map(&:to_i)
      ActiveSupport::TimeZone[merchant.timezone].local(delivery_date.year, delivery_date.month, delivery_date.day, hour, minute)
    end

    def build_route(orders, depot)
      route = merchant.routes.create!(
        delivery_date: delivery_date,
        engine: @engine.name,
        start_at: start_at,
        start_lat: depot.lat,
        start_lng: depot.lng
      )
      clock = start_at
      total_km = 0.0
      prev_lat = depot.lat
      prev_lng = depot.lng

      orders.each_with_index do |order, index|
        leg = Distance.road_km(prev_lat, prev_lng, order.lat.to_f, order.lng.to_f)
        clock += (leg / AVERAGE_KMH * 60).minutes
        total_km += leg
        route.route_stops.create!(order: order, position: index + 1, lat: order.lat, lng: order.lng, leg_km: leg.round(2), eta: clock)
        clock += SERVICE_MINUTES.minutes
        prev_lat = order.lat.to_f
        prev_lng = order.lng.to_f
      end

      Order.where(id: orders.map(&:id)).update_all(status: "routed", updated_at: Time.current)
      route.update!(stop_count: orders.size, distance_km: total_km.round(2), duration_minutes: ((clock - start_at) / 60).round)
      route
    end

    def touched_batches(orders)
      Batch.where(id: orders.map(&:batch_id).uniq)
    end
  end
end
