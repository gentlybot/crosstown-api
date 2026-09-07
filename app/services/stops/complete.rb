module Stops
  # A courier marks a stop delivered or failed. Updates the order, finishes the
  # route when every stop is settled, and tells the recipient.
  class Complete
    class Invalid < StandardError; end

    MAX_PHOTO_BYTES = 1_500_000

    def initialize(stop, status:, note: nil, failure_reason: nil, photo_data: nil)
      @stop = stop
      @status = status.to_s
      @note = note.presence
      @failure_reason = failure_reason.presence
      @photo_data = photo_data.presence
    end

    def call
      raise Invalid, "Status must be delivered or failed." unless %w[delivered failed].include?(@status)
      raise Invalid, "Pick a reason the delivery failed." if @status == "failed" && @failure_reason.blank?
      raise Invalid, "Reason must be one of #{RouteStop::FAILURE_REASONS.join(', ')}." if @failure_reason && !RouteStop::FAILURE_REASONS.include?(@failure_reason)
      raise Invalid, "That photo is too large." if @photo_data && @photo_data.bytesize > MAX_PHOTO_BYTES
      raise Invalid, "Photos must be image data URLs." if @photo_data && !@photo_data.start_with?("data:image/")
      raise Invalid, "Start the route before marking stops." unless @stop.route.in_progress?

      now = Time.current
      Route.transaction do
        @stop.update!(status: @status, completed_at: now, note: @note, failure_reason: @status == "failed" ? @failure_reason : nil, photo_data: @photo_data)
        @stop.order.update!(status: @status)
        @stop.route.settle_if_finished!
      end
      RecipientMailer.stop_update(@stop).deliver_later if @stop.order.recipient_email.present?
      @stop
    end
  end
end
