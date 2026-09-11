module DeliveryAllowances
  # Dedicated demo ledger. Ordinary seeds preserve activity; the explicit reset
  # clears reservations only for these two fictional merchants in this period.
  module DemoSeed
    def self.call(reset: false)
      {
        "bloom-and-stem" => {
          "same_day" => [ 500, true, 245, 75, 80 ],
          "next_day" => [ 300, true, 40, 0, nil ],
          "return_pickup" => [ 30, true, 10, 0, 0 ],
          "redelivery" => [ 20, true, 20, 0, 10 ]
        },
        "corner-loaf" => {
          "same_day" => [ 100, true, 30, 0, nil ],
          "next_day" => [ 100, true, 10, 0, nil ],
          "return_pickup" => [ 0, false, 0, 0, nil ],
          "redelivery" => [ 10, true, 2, 0, nil ]
        }
      }.each do |slug, services|
        merchant = Merchant.find_by!(slug: slug)
        owner = merchant.users.merchant_admin.order(:id).first!
        staff = merchant.users.find_by(email: "sam@bloomandstem.example")
        period = Balance.new(owner).period_start
        merchant.with_lock do
          services.each do |type, (limit, enabled, owner_used, staff_used, staff_limit)|
            allowance = merchant.delivery_allowances.find_or_initialize_by(service_type: type)
            allowance.assign_attributes(monthly_limit: limit, enabled: enabled) if allowance.new_record? || reset
            allowance.save!
            if reset
              allowance.delivery_reservations.where(period_start: period).destroy_all
              allowance.staff_delivery_limits.destroy_all
            end
            if staff && !staff_limit.nil?
              allowance.staff_delivery_limits.find_or_create_by!(user: staff) { |row| row.monthly_limit = staff_limit }
            end
            [ [ owner, owner_used ], [ staff, staff_used ] ].each do |user, units|
              next unless user && units.positive?
              allowance.delivery_reservations.find_or_create_by!(user: user, request_key: "demo:#{type}:#{period}") do |row|
                row.assign_attributes(period_start: period, units: units)
              end
            end
          end
        end
      end
    end
  end
end
