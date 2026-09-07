module Api
  module V1
    module MerchantArea
      # Merchants can route their own day without waiting for ops.
      class RoutesController < BaseController
        before_action :require_merchant!

        # GET /api/v1/merchant/routes?date=YYYY-MM-DD
        def index
          date = parse_date(params[:date]) || Date.current
          orders = current_merchant.orders.joins(:batch).where(batches: { delivery_date: date })
          routes = current_merchant.routes.where(delivery_date: date).where.not(status: "cancelled").includes(:courier, route_stops: :order).order(:route_number)
          render json: {
            date: date.iso8601,
            ready_unrouted: orders.where(status: "ready").where.not(lat: nil).count,
            unplaced: orders.where(status: "ready", lat: nil).count,
            routed: orders.where(status: "routed").count,
            plan: RoutePlanSerializer.call(RoutePlan.find_by(merchant: current_merchant, delivery_date: date)),
            routes: routes.map { |r| RouteSerializer.summary(r) }
          }
        end

        # POST /api/v1/merchant/routes/build { date }
        def build
          date = parse_date(params[:date]) || Date.current
          plan = RoutePlan.find_or_initialize_by(merchant: current_merchant, delivery_date: date)
          unless plan.persisted? && plan.building?
            plan.assign_attributes(status: "queued", error: nil, requested_by: current_user, started_at: nil, finished_at: nil)
            plan.save!
            BuildRoutesJob.perform_later(current_merchant.id, date.iso8601)
          end
          render json: { plan: RoutePlanSerializer.call(plan) }, status: :accepted
        end

        private

        def parse_date(value)
          Date.iso8601(value.to_s)
        rescue Date::Error
          nil
        end
      end
    end
  end
end
