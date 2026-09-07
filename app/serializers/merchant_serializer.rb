module MerchantSerializer
  def self.call(merchant)
    {
      id: merchant.id,
      business_name: merchant.business_name,
      slug: merchant.slug,
      contact_name: merchant.contact_name,
      contact_email: merchant.contact_email,
      phone: merchant.phone,
      pickup_address: merchant.pickup_address,
      cutoff_time: merchant.cutoff_time,
      timezone: merchant.timezone
    }
  end
end
