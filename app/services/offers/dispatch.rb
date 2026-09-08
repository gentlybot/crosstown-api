module Offers
  # Sends a planned route to every active courier who is available on its delivery day.
  class Dispatch
    OFFER_WINDOW = 20.minutes

    class NotOfferable < StandardError; end

    def initialize(route)
      @route = route
    end

    def call
      offers = []
      Route.transaction do
        # Availability removal locks its date row before it examines routes.
        # Keep that lock while selecting and creating offers so a courier who
        # becomes unavailable cannot receive a newly-created offer.
        couriers = available_couriers
        route = Route.lock.find(@route.id)
        raise NotOfferable, "#{route.display_name} is #{route.status.humanize.downcase}, not planned." unless route.planned? || route.offered?
        if couriers.empty?
          raise NotOfferable, "There are no active couriers available for #{route.display_name} on #{route.delivery_date.strftime('%B %-d')}."
        end

        now = Time.current
        pay = Routing::Pay.cents(route)
        route.update!(status: "offered", offered_at: now, pay_cents: pay)
        couriers.each do |courier|
          offer = RouteOffer.find_or_initialize_by(route: route, courier: courier)
          next if offer.persisted? && offer.declined?
          offer.assign_attributes(status: "offered", pay_cents: pay, offered_at: now, expires_at: now + OFFER_WINDOW, responded_at: nil)
          offer.save!
          offers << offer
        end

        @route = route
        @offer_window_ends_at = now + OFFER_WINDOW
      end
      offers.each { |offer| CourierMailer.route_offered(offer).deliver_later }
      ExpireOffersJob.set(wait_until: @offer_window_ends_at + 5.seconds).perform_later(@route.id)
      offers
    end

    private

    def available_couriers
      availability_rows = CourierAvailability.joins(:courier)
        .merge(Courier.active)
        .on(@route.delivery_date)
        .order(:courier_id)
        .lock("FOR UPDATE OF courier_availabilities")
        .to_a

      Courier.where(id: availability_rows.map(&:courier_id)).includes(:user).order(:id).to_a
    end
  end
end
