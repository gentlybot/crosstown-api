module Api
  module V1
    module CourierArea
      class RoutesController < BaseController
        before_action :require_courier!

        def index
          routes = current_courier.routes.where(status: %w[assigned in_progress completed]).includes(:merchant, route_stops: :order).order(delivery_date: :desc, start_at: :asc).limit(50)
          render json: { routes: routes.map { |r| RouteSerializer.for_courier(r) } }
        end

        def show
          route = current_courier.routes.includes(:merchant, route_stops: :order).find(params[:id])
          render json: { route: RouteSerializer.for_courier(route) }
        end

        def start
          route = current_courier.routes.find(params[:id])
          unless route.assigned?
            return render json: { error: "#{route.display_name} is #{route.status.humanize.downcase}." }, status: 422
          end
          route.update!(status: "in_progress", started_at: Time.current)
          render json: { route: RouteSerializer.for_courier(route) }
        end
      end
    end
  end
end
