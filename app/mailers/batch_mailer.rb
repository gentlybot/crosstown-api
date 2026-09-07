class BatchMailer < ApplicationMailer
  def import_finished(batch)
    @batch = batch
    @merchant = batch.merchant
    @portal_url = ENV.fetch("PORTAL_URL", "http://localhost:5200")
    recipient = batch.created_by&.email || @merchant.contact_email
    subject =
      if batch.problem_count.positive?
        "#{batch.name}: #{batch.problem_count} of #{batch.row_count} orders need attention"
      else
        "#{batch.name}: #{batch.row_count} orders ready"
      end
    mail(to: recipient, subject: subject)
  end
end
