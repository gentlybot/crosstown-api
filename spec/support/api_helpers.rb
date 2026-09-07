module ApiHelpers
  def auth_headers(user)
    { "Authorization" => "Bearer #{AuthToken.issue(user)}" }
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
  config.include ActiveJob::TestHelper, type: :request
end
