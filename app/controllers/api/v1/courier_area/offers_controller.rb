module Api
  module V1
    module CourierArea
      class OffersController < BaseController
        before_action :require_courier!

        def index
          offers = current_courier.route_offers.open.includes(route: [:merchant, { route_stops: :order }]).order(:expires_at)
          render json: { offers: offers.map { |o| RouteOfferSerializer.for_courier(o) } }
        end

        def accept
          offer = current_courier.route_offers.find(params[:id])
          route = Offers::Accept.new(offer).call
          render json: { route: RouteSerializer.for_courier(route) }
        rescue Offers::Accept::Unavailable => e
          render json: { error: e.message }, status: :conflict
        end

        def decline
          offer = current_courier.route_offers.find(params[:id])
          offer.update!(status: "declined", responded_at: Time.current) if offer.offered?
          head :no_content
        end
      end
    end
  end
end
