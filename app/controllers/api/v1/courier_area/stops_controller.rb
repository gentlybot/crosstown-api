module Api
  module V1
    module CourierArea
      class StopsController < BaseController
        before_action :require_courier!

        # PATCH /api/v1/courier/routes/:route_id/stops/:id
        # { status: "delivered" | "failed", note, failure_reason, photo (data URL) }
        def update
          route = current_courier.routes.find(params[:route_id])
          stop = route.route_stops.find(params[:id])
          Stops::Complete.new(stop, status: params[:status], note: params[:note], failure_reason: params[:failure_reason], photo_data: params[:photo]).call
          render json: { route: RouteSerializer.for_courier(route.reload) }
        rescue Stops::Complete::Invalid => e
          render json: { error: e.message }, status: 422
        end
      end
    end
  end
end
