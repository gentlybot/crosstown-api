module Api
  module V1
    module MerchantArea
      class DeliveryReservationsController < BaseController
        before_action :require_merchant!

        def create
          reservation = DeliveryAllowances::Reserve.new(
            current_user, service_type: params[:service_type], units: params[:units], request_key: params[:request_key]
          ).call
          render json: { reservation: serialize(reservation), balance: DeliveryAllowances::Balance.new(current_user).call }
        rescue DeliveryAllowances::Reserve::Invalid => e
          render json: { error: e.message }, status: 422
        rescue DeliveryAllowances::Reserve::Conflict => e
          render json: { error: e.message }, status: :conflict
        end

        def destroy
          current_merchant.with_lock do
            reservation = current_user.delivery_reservations.joins(:delivery_allowance)
              .where(delivery_allowances: { merchant_id: current_merchant.id }).find(params[:id])
            reservation.update!(cancelled_at: Time.current) unless reservation.cancelled_at
          end
          head :no_content
        end

        private

        def serialize(reservation)
          {
            id: reservation.id, service_type: reservation.delivery_allowance.service_type,
            units: reservation.units, period_start: reservation.period_start.iso8601,
            request_key: reservation.request_key, cancelled_at: reservation.cancelled_at&.iso8601
          }
        end
      end
    end
  end
end
