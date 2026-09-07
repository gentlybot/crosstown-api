module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate!

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found." }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: e.record.errors.full_messages.to_sentence, errors: e.record.errors.to_hash }, status: 422
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: { error: e.message }, status: :bad_request
      end

      private

      attr_reader :current_user

      def authenticate!
        token = request.authorization.to_s.sub(/\ABearer\s+/i, "")
        payload = AuthToken.read(token)
        @current_user = payload && User.find_by(id: payload["sub"])
        render json: { error: "Sign in to continue." }, status: :unauthorized unless @current_user
      end

      def current_merchant
        current_user&.merchant
      end

      def require_merchant!
        return if current_merchant
        render json: { error: "This account is not attached to a merchant." }, status: :forbidden
      end

      def require_admin!
        return if current_user.admin?
        render json: { error: "Handoff staff only." }, status: :forbidden
      end
    end
  end
end
