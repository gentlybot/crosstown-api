class ExpireOffersJob < ApplicationJob
  queue_as :default

  def perform(route_id)
    route = Route.find_by(id: route_id)
    Offers::Expire.new(route).call if route
  end
end
