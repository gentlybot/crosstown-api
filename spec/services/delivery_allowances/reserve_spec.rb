require "rails_helper"

RSpec.describe DeliveryAllowances::Reserve, type: :request do
  # Separate connections must see committed rows to exercise the merchant lock.
  self.use_transactional_tests = false

  it "allows only one simultaneous booking when staff compete for the last capacity" do
    merchant = create(:merchant)
    users = 2.times.map { create(:user, merchant: merchant, role: "merchant_staff") }
    allowance = merchant.delivery_allowances.create!(service_type: "same_day", monthly_limit: 5)
    ready = Queue.new
    start = Queue.new
    threads = users.map do |user|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          described_class.new(User.find(user.id), service_type: "same_day", units: 4, request_key: "simultaneous").call
          :reserved
        rescue DeliveryAllowances::Reserve::Invalid
          :blocked
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    expect(threads.map(&:value)).to contain_exactly(:reserved, :blocked)
    expect(allowance.delivery_reservations.sum(:units)).to eq(4)
  ensure
    threads&.each(&:join)
    merchant&.destroy!
  end
end
