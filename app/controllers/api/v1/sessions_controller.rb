module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate!, only: :create

      def create
        user = User.find_by("lower(email) = ?", params[:email].to_s.strip.downcase)
        unless user&.authenticate(params[:password].to_s)
          return render json: { error: "Email or password is wrong." }, status: :unauthorized
        end

        user.touch(:last_signed_in_at)
        render json: {
          token: AuthToken.issue(user),
          user: UserSerializer.call(user),
          merchant: user.merchant && MerchantSerializer.call(user.merchant)
        }, status: :created
      end

      # Tokens are stateless; the client forgets it. Kept so the SPA has an
      # endpoint to call and so revocation has a place to land later.
      def destroy
        head :no_content
      end
    end
  end
end
