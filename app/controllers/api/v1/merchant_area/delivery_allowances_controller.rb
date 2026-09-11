module Api
  module V1
    module MerchantArea
      class DeliveryAllowancesController < BaseController
        before_action :require_merchant!

        def index
          render json: DeliveryAllowances::Balance.new(current_user).call
        end
      end
    end
  end
end
