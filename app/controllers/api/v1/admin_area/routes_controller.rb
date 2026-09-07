module Api
  module V1
    module AdminArea
      # Ops routing: what still needs routes for a day, what has been built, and
      # a button to build or rebuild per merchant.
      class RoutesController < BaseController
        before_action :require_admin!

        def index
          date = parse_date(params[:date]) || Date.current
          merchant_ids = Batch.where(delivery_date: date).select(:merchant_id)
          merchants = Merchant.where(id: merchant_ids).or(Merchant.where(id: Route.where(delivery_date: date).select(:merchant_id))).order(:business_name)
          plans = RoutePlan.where(delivery_date: date).index_by(&:merchant_id)

          entries = merchants.map do |merchant|
            orders = merchant.orders.joins(:batch).where(batches: { delivery_date: date })
            routes = merchant.routes.where(delivery_date: date).where.not(status: "cancelled").includes(:courier, route_offers: { courier: :user }, route_stops: :order).order(:route_number)
            {
              merchant: MerchantSerializer.brief(merchant),
              ready_unrouted: orders.where(status: "ready").where.not(lat: nil).count,
              unplaced: orders.where(status: "ready", lat: nil).count,
              routed: orders.where(status: "routed").count,
              problems: orders.where(status: "problem").count,
              plan: RoutePlanSerializer.call(plans[merchant.id]),
              routes: routes.map { |r| RouteSerializer.detail(r) }
            }
          end

          render json: {
            date: date.iso8601,
            engine: Routing::Engine.default.name,
            totals: {
              merchants: entries.size,
              routes: entries.sum { |e| e[:routes].size },
              stops: entries.sum { |e| e[:routes].sum { |r| r[:stop_count] } },
              unrouted: entries.sum { |e| e[:ready_unrouted] },
              building: entries.count { |e| e[:plan] && %w[queued running].include?(e[:plan][:status]) }
            },
            merchants: entries
          }
        end

        def show
          route = Route.includes(:merchant, route_stops: :order).find(params[:id])
          render json: { route: RouteSerializer.detail(route) }
        end

        # POST /api/v1/admin/routes/:id/offer
        def offer
          route = Route.find(params[:id])
          Offers::Dispatch.new(route).call
          render json: { route: RouteSerializer.detail(route.reload) }
        rescue Offers::Dispatch::NotOfferable => e
          render json: { error: e.message }, status: 422
        end

        # POST /api/v1/admin/routes/build { merchant_id, date }
        def build
          merchant = Merchant.find(params.require(:merchant_id))
          date = parse_date(params[:date]) || Date.current
          plan = RoutePlan.find_or_initialize_by(merchant: merchant, delivery_date: date)
          if plan.persisted? && plan.building?
            return render json: { plan: RoutePlanSerializer.call(plan) }, status: :accepted
          end
          plan.assign_attributes(status: "queued", error: nil, requested_by: current_user, started_at: nil, finished_at: nil)
          plan.save!
          BuildRoutesJob.perform_later(merchant.id, date.iso8601)
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
