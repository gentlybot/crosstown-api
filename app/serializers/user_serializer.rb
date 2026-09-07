module UserSerializer
  def self.call(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      merchant_id: user.merchant_id,
      courier_id: user.courier&.id
    }
  end
end
