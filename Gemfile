source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.3", ">= 7.2.3.2"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"
# Bundled gem from Ruby 3.4 on; used by the batch importer.
gem "csv"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# json 2.10 dropped the quirks_mode option that ActiveSupport 7.2 still passes.
gem "json", "< 2.10"

# Background jobs and the Sidekiq web UI (mounted at /sidekiq).
gem "sidekiq", "~> 7.3"
# Sidekiq 7.3 still calls ConnectionPool::TimedStack#pop(timeout), which
# connection_pool 3.0 removed; without this pin the scheduler thread dies at
# boot and delayed jobs (offer expiry) never run.
gem "connection_pool", "< 3"
# Cross-origin requests from the portal and courier apps.
gem "rack-cors"
# Token auth for the SPA clients.
gem "jwt"
gem "bcrypt", "~> 3.1"
# JSON views for the older API namespace.
gem "jbuilder"
# Bundled gem from Ruby 3.4 on; used by the batch importer.

# Loads .env files in development and test.
gem "dotenv-rails", groups: [:development, :test]

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"
  gem "faker"
end


