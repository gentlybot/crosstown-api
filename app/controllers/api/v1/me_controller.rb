module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          user: UserSerializer.call(current_user),
          merchant: current_merchant && MerchantSerializer.call(current_merchant),
          courier: current_user.courier && CourierSerializer.call(current_user.courier)
        }
      end
    end
  end
end
