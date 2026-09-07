module Api
  module V1
    module MerchantArea
      class BatchesController < BaseController
        MAX_FILE_BYTES = 2.megabytes

        before_action :require_merchant!

        def index
          batches = current_merchant.batches.recent.limit(100)
          render json: { batches: batches.map { |b| BatchSerializer.summary(b) } }
        end

        def show
          batch = current_merchant.batches.find(params[:id])
          render json: { batch: BatchSerializer.detail(batch) }
        end

        # Multipart: file (CSV), delivery_date (YYYY-MM-DD, optional), name (optional).
        # Returns 202: the rows are parsed by ImportBatchJob and the client polls.
        def create
          file = params.require(:file)
          unless file.respond_to?(:read)
            return render json: { error: "Attach a CSV file as the file field." }, status: :bad_request
          end
          if file.size.to_i > MAX_FILE_BYTES
            return render json: { error: "That file is over 2 MB. Split it into smaller batches." }, status: 422
          end

          delivery_date = parse_date(params[:delivery_date]) || Date.tomorrow
          filename = file.respond_to?(:original_filename) ? file.original_filename : nil
          name = params[:name].presence || default_name(delivery_date)

          batch = current_merchant.batches.create!(
            name: name,
            delivery_date: delivery_date,
            source: "csv",
            original_filename: filename,
            raw_csv: file.read.force_encoding("UTF-8"),
            created_by: current_user
          )
          ImportBatchJob.perform_later(batch.id)

          render json: { batch: BatchSerializer.summary(batch) }, status: :accepted
        end

        private

        def parse_date(value)
          Date.iso8601(value.to_s)
        rescue Date::Error
          nil
        end

        def default_name(delivery_date)
          "Orders for #{delivery_date.strftime('%a %-d %b')}"
        end
      end
    end
  end
end
