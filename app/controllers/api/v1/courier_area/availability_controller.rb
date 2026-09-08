module Api
  module V1
    module CourierArea
      class AvailabilityController < BaseController
        before_action :require_courier!

        # GET /api/v1/courier/availability?from=YYYY-MM-DD&to=YYYY-MM-DD
        def show
          from = parse_date(params[:from]) || Date.current
          to = parse_date(params[:to]) || from + 13.days
          return render json: { error: "Choose an end date on or after the start date." }, status: 422 if to < from

          dates = current_courier.courier_availabilities.between(from, to).order(:availability_date).pluck(:availability_date)
          render json: { availability_dates: dates.map(&:iso8601) }
        end

        # PATCH /api/v1/courier/availability { date: YYYY-MM-DD, available: true|false }
        def update
          date = parse_date(params[:date])
          return render json: { error: "Choose a valid availability date." }, status: 422 unless date
          return render json: { error: "Availability can only be changed for today or later." }, status: 422 if date < Date.current
          available = params[:available]
          return render json: { error: "Say whether you are available." }, status: 422 unless [ true, false ].include?(available)

          Courier.transaction do
            if available
              current_courier.courier_availabilities.find_or_create_by!(availability_date: date)
            else
              availability = current_courier.courier_availabilities.lock.find_by(availability_date: date)
              withdraw_open_offers_for(date)
              availability&.destroy!
            end
          end

          render json: { date: date.iso8601, available: available }
        end

        private

        def parse_date(value)
          Date.iso8601(value.to_s)
        rescue Date::Error
          nil
        end

        def withdraw_open_offers_for(date)
          route_ids = current_courier.route_offers.open.joins(:route).where(routes: { delivery_date: date }).distinct.order(:route_id).pluck(:route_id)
          now = Time.current

          route_ids.each do |route_id|
            route = Route.lock.find(route_id)
            offer = current_courier.route_offers.open.lock.find_by(route: route)
            next unless offer

            offer.update!(status: "withdrawn", responded_at: now)
            route.update!(status: "planned") if route.offered? && route.route_offers.offered.none?
          end
        end
      end
    end
  end
end
