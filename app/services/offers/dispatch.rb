module Offers
  # Sends a planned route to every active courier who is available on its delivery day.
  class Dispatch
    OFFER_WINDOW = 20.minutes

    class NotOfferable < StandardError; end

    def initialize(route)
      @route = route
    end

    def call
      raise NotOfferable, "#{@route.display_name} is #{@route.status.humanize.downcase}, not planned." unless @route.planned? || @route.offered?
      couriers = Courier.available_on(@route.delivery_date).includes(:user).to_a
      if couriers.empty?
        raise NotOfferable, "There are no active couriers available for #{@route.display_name} on #{@route.delivery_date.strftime('%B %-d')}."
      end

      now = Time.current
      pay = Routing::Pay.cents(@route)
      offers = []
      Route.transaction do
        @route.update!(status: "offered", offered_at: now, pay_cents: pay)
        couriers.each do |courier|
          offer = RouteOffer.find_or_initialize_by(route: @route, courier: courier)
          next if offer.persisted? && offer.declined?
          offer.assign_attributes(status: "offered", pay_cents: pay, offered_at: now, expires_at: now + OFFER_WINDOW, responded_at: nil)
          offer.save!
          offers << offer
        end
      end
      offers.each { |offer| CourierMailer.route_offered(offer).deliver_later }
      ExpireOffersJob.set(wait_until: now + OFFER_WINDOW + 5.seconds).perform_later(@route.id)
      offers
    end
  end
end
