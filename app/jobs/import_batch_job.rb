class ImportBatchJob < ApplicationJob
  queue_as :default

  def perform(batch_id)
    batch = Batch.find(batch_id)
    return unless batch.importing?

    Batches::CsvImporter.new(batch).call
    BatchMailer.import_finished(batch).deliver_later
  rescue Batches::CsvImporter::InvalidFile => e
    batch.update!(status: "failed", error_message: e.message)
  end
end
