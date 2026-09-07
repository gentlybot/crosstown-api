module CourierSerializer
  def self.call(courier)
    {
      id: courier.id,
      name: courier.name,
      email: courier.email,
      phone: courier.phone,
      vehicle_type: courier.vehicle_type,
      home_fsa: courier.home_fsa,
      status: courier.status
    }
  end

  def self.brief(courier)
    return nil unless courier
    { id: courier.id, name: courier.name, vehicle_type: courier.vehicle_type }
  end
end
