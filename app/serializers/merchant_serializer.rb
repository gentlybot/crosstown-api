module MerchantSerializer
  def self.brief(merchant)
    {
      id: merchant.id,
      business_name: merchant.business_name,
      slug: merchant.slug,
      cutoff_time: merchant.cutoff_time,
      pickup_address: merchant.pickup_address,
      pickup_lat: merchant.pickup_lat&.to_f,
      pickup_lng: merchant.pickup_lng&.to_f
    }
  end

  def self.call(merchant)
    {
      id: merchant.id,
      business_name: merchant.business_name,
      slug: merchant.slug,
      contact_name: merchant.contact_name,
      contact_email: merchant.contact_email,
      phone: merchant.phone,
      pickup_address: merchant.pickup_address,
      pickup_lat: merchant.pickup_lat&.to_f,
      pickup_lng: merchant.pickup_lng&.to_f,
      cutoff_time: merchant.cutoff_time,
      timezone: merchant.timezone
    }
  end
end
