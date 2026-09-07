module Api
  module V1
    module AdminArea
      class MerchantsController < BaseController
        before_action :require_admin!

        def index
          merchants = Merchant.order(:business_name)
          render json: { merchants: merchants.map { |m| MerchantSerializer.call(m) } }
        end
      end
    end
  end
end
