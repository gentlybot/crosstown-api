module DeliveryAllowances
  class Balance
    def initialize(user, now: Time.current)
      @user = user
      @merchant = user.merchant
      @period_start = now.in_time_zone(@merchant.timezone).to_date.beginning_of_month
    end

    attr_reader :period_start

    def call
      {
        period_start: period_start.iso8601,
        resets_on: period_start.next_month.iso8601,
        timezone: @merchant.timezone,
        merchant: { id: @merchant.id, name: @merchant.business_name },
        user: { id: @user.id, name: @user.name },
        allowances: Catalog::SERVICES.map { |type, details| entry(type, details) }
      }
    end

    def entry(type, details = Catalog::SERVICES.fetch(type))
      allowance = @merchant.delivery_allowances.find_by(service_type: type)
      enabled = allowance&.enabled? || false
      reservations = allowance&.delivery_reservations&.active&.where(period_start: period_start)
      used_by_user = reservations&.group(:user_id)&.sum(:units) || {}
      merchant_used = used_by_user.values.sum
      personal_used = used_by_user.fetch(@user.id, 0)
      merchant_limit = allowance&.monthly_limit || 0
      personal_limit = allowance&.staff_delivery_limits&.find_by(user: @user)&.monthly_limit
      merchant_remaining = [ merchant_limit - merchant_used, 0 ].max
      personal_remaining = personal_limit.nil? ? nil : [ personal_limit - personal_used, 0 ].max
      available = enabled ? [ merchant_remaining, personal_remaining ].compact.min : 0
      blocked_by = []
      if !enabled
        blocked_by << "service_disabled"
      else
        blocked_by << "merchant_limit" if merchant_remaining.zero?
        blocked_by << "personal_limit" if personal_remaining == 0
      end

      details.merge(
        service_type: type, enabled: enabled, unit: "jobs",
        merchant: { limit: merchant_limit, used: merchant_used, remaining: merchant_remaining },
        personal: { limit: personal_limit, used: personal_used, remaining: personal_remaining },
        available_to_you: available, blocked_by: blocked_by
      )
    end
  end
end
