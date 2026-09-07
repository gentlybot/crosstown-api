class RecipientMailer < ApplicationMailer
  def stop_update(stop)
    @stop = stop
    @order = stop.order
    @merchant = @order.merchant
    @when = stop.completed_at.in_time_zone(@merchant.timezone).strftime("%-l:%M %p")
    subject =
      if stop.delivered?
        "Your order from #{@merchant.business_name} was delivered at #{@when}"
      else
        "We could not deliver your order from #{@merchant.business_name}"
      end
    mail(to: @order.recipient_email, subject: subject)
  end
end
