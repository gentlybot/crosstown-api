module Api
  module V1
    module AdminArea
      class PricingController < BaseController
        before_action :require_admin!

        def show
          render json: payload
        end

        def update
          PricingSetting.current.update!(default_per_stop_price_cents: pricing_params[:default_per_stop_price_cents]) if pricing_params.key?(:default_per_stop_price_cents)

          pricing_params.fetch(:merchant_prices, []).each do |price|
            Merchant.find(price[:merchant_id]).update!(per_stop_price_cents: price[:per_stop_price_cents].presence)
          end

          render json: payload
        end

        private

        def pricing_params
          params.permit(:default_per_stop_price_cents, merchant_prices: %i[merchant_id per_stop_price_cents])
        end

        def payload
          setting = PricingSetting.current
          {
            pricing: {
              default_per_stop_price_cents: setting.default_per_stop_price_cents,
              merchants: Merchant.order(:business_name).map do |merchant|
                {
                  id: merchant.id,
                  business_name: merchant.business_name,
                  per_stop_price_cents: merchant.per_stop_price_cents,
                  effective_per_stop_price_cents: Pricing::PerStop.cents_for(merchant)
                }
              end
            }
          }
        end
      end
    end
  end
end