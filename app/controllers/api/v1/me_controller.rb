module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          user: UserSerializer.call(current_user),
          merchant: current_merchant && MerchantSerializer.call(current_merchant)
        }
      end
    end
  end
end
