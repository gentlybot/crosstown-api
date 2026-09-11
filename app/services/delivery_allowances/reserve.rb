module DeliveryAllowances
  # A merchant lock serializes reservations across staff sharing one allowance.
  # Retries reuse a request key; cancelling releases both shared and personal use.
  class Reserve
    class Invalid < StandardError; end
    class Conflict < StandardError; end

    def initialize(user, service_type:, units:, request_key:)
      @user, @service_type, @units, @request_key = user, service_type, units, request_key
    end

    def call
      raise Invalid, "Choose a delivery service from the catalog." unless Catalog::SERVICES.key?(@service_type)
      raise Invalid, "Units must be a whole number of 1 or more." unless @units.is_a?(Integer) && @units.positive?
      raise Invalid, "Supply a request key of 1 to 120 characters." unless @request_key.is_a?(String) && @request_key.present? && @request_key.length <= 120

      @user.merchant.with_lock do
        existing = @user.delivery_reservations.find_by(request_key: @request_key)
        if existing
          unless existing.units == @units && existing.delivery_allowance.service_type == @service_type && existing.delivery_allowance.merchant_id == @user.merchant_id
            raise Conflict, "That request key was used for a different reservation."
          end
          return existing
        end

        balance = Balance.new(@user)
        entry = balance.entry(@service_type)
        raise Invalid, "This delivery service is not enabled for your merchant." unless entry[:enabled]
        raise Invalid, "Your merchant does not have enough of this allowance left." if entry[:merchant][:remaining] < @units
        if entry[:personal][:remaining] && entry[:personal][:remaining] < @units
          raise Invalid, "Your personal limit does not have enough of this allowance left."
        end

        @user.merchant.delivery_allowances.find_by!(service_type: @service_type).delivery_reservations.create!(
          user: @user, units: @units, request_key: @request_key, period_start: balance.period_start
        )
      end
    end
  end
end
