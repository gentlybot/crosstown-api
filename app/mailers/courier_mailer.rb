class CourierMailer < ApplicationMailer
  def route_offered(offer)
    @offer = offer
    @route = offer.route
    @merchant = @route.merchant
    @pay = format("$%.2f", offer.pay_cents / 100.0)
    mail(to: offer.courier.email, subject: "#{@route.display_name}: #{@route.stop_count} stops, #{@pay}, leaves #{@route.start_at.in_time_zone(@merchant.timezone).strftime('%-l:%M %p')}")
  end
end
