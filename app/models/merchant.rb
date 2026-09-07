class Merchant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :batches, dependent: :destroy
  has_many :orders, dependent: :destroy

  before_validation :assign_slug, on: :create

  validates :business_name, :contact_email, :pickup_address_line, :pickup_city, :pickup_postal_code, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :cutoff_time, format: { with: /\A\d{2}:\d{2}\z/, message: "must look like 14:00" }

  def pickup_address
    [pickup_address_line, pickup_unit.presence, pickup_city, pickup_postal_code].compact.join(", ")
  end

  private

  def assign_slug
    self.slug = business_name.to_s.parameterize if slug.blank? && business_name.present?
  end
end
