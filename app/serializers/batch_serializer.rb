module BatchSerializer
  def self.summary(batch)
    {
      id: batch.id,
      name: batch.name,
      status: batch.status,
      source: batch.source,
      delivery_date: batch.delivery_date.iso8601,
      original_filename: batch.original_filename,
      row_count: batch.row_count,
      ready_count: batch.ready_count,
      problem_count: batch.problem_count,
      error_message: batch.error_message,
      imported_at: batch.imported_at&.iso8601,
      created_at: batch.created_at.iso8601,
      created_by: batch.created_by&.name
    }
  end

  def self.detail(batch)
    summary(batch).merge(
      orders: batch.orders.order(:row_number).map { |o| OrderSerializer.call(o) }
    )
  end
end
