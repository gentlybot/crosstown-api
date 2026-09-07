module Api
  module V1
    module AdminArea
      # Ops view: every merchant's batches for one delivery day.
      class BatchesController < BaseController
        before_action :require_admin!

        def index
          date = parse_date(params[:date]) || Date.current
          scope = Batch.includes(:merchant, :created_by).joins(:merchant).where(delivery_date: date)
          scope = scope.where(merchant_id: params[:merchant_id]) if params[:merchant_id].present?
          scope = scope.where(status: params[:status]) if params[:status].present? && Batch::STATUSES.include?(params[:status])
          batches = scope.order("merchants.business_name ASC, batches.created_at DESC").to_a

          render json: {
            date: date.iso8601,
            totals: totals_for(batches),
            batches: batches.map { |b| BatchSerializer.summary(b, include_merchant: true) }
          }
        end

        def show
          batch = Batch.includes(:merchant, :created_by).find(params[:id])
          render json: { batch: BatchSerializer.detail(batch, include_merchant: true) }
        end

        private

        def totals_for(batches)
          {
            batches: batches.size,
            merchants: batches.map(&:merchant_id).uniq.size,
            orders: batches.sum(&:row_count),
            ready: batches.sum(&:ready_count),
            problems: batches.sum(&:problem_count),
            importing: batches.count(&:importing?),
            failed: batches.count(&:failed?)
          }
        end

        def parse_date(value)
          Date.iso8601(value.to_s)
        rescue Date::Error
          nil
        end
      end
    end
  end
end
