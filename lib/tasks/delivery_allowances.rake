namespace :demo do
  desc "Reset this month's delivery allowances for Bloom & Stem and Corner Loaf (does not change routes or orders)"
  task reset_delivery_allowances: :environment do
    abort "Demo reset is disabled in production." if Rails.env.production?
    DeliveryAllowances::DemoSeed.call(reset: true)
    puts "Delivery allowances reset for the current merchant-local month."
  end
end
