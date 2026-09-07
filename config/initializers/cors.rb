# Browser clients (the portal and the courier app) run on other origins in
# development. In the sandbox everything is same-origin and this is inert.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:5200").split(",").map(&:strip)
    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Location]
  end
end
