namespace :demo do
  desc "Seed the 24 MCP merchants and demo logins without changing deliveries"
  task seed_merchants: :environment do
    abort "Demo merchant seeding is disabled in production." if Rails.env.production?
    count = Demo::MerchantSeed.call
    puts "Seeded #{count} demo merchants and their logins. New accounts use password: #{Demo::MerchantSeed::PASSWORD}"
  end
end
