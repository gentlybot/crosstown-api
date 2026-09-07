module BatchSerializer
  # include_merchant: true adds a brief merchant block, for cross-merchant (ops) views.
  def self.summary(batch, include_merchant: false)
    base = {
      id: batch.id,
      name: batch.name,
      status: batch.status,
      source: batch.source,
      delivery_date: batch.delivery_date.iso8601,
      original_filename: batch.original_filename,
      row_count: batch.row_count,
      ready_count: batch.ready_count,
      problem_count: batch.problem_count,
      routed_count: batch.routed_count,
      error_message: batch.error_message,
      imported_at: batch.imported_at&.iso8601,
      created_at: batch.created_at.iso8601,
      created_by: batch.created_by&.name
    }
    base[:merchant] = MerchantSerializer.brief(batch.merchant) if include_merchant
    base
  end

  def self.detail(batch, include_merchant: false)
    routes = Route.where(id: RouteStop.where(order_id: batch.orders.select(:id)).select(:route_id)).order(:route_number)
    summary(batch, include_merchant: include_merchant).merge(
      orders: batch.orders.includes(route_stop: :route).order(:row_number).map { |o| OrderSerializer.call(o) },
      routes: routes.map { |r| RouteSerializer.summary(r) }
    )
  end
end
