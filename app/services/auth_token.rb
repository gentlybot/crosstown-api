# Signed bearer tokens for the SPA clients. HS256 with the app secret, thirty
# day expiry. A stolen token cannot be revoked short of rotating the secret,
# which is how the original app worked too.
module AuthToken
  ALGORITHM = "HS256"
  TTL = 30.days

  def self.issue(user)
    payload = { sub: user.id, role: user.role, exp: TTL.from_now.to_i, iat: Time.current.to_i }
    JWT.encode(payload, secret, ALGORITHM)
  end

  # Returns the payload hash, or nil when the token is missing, expired, or forged.
  def self.read(token)
    return nil if token.blank?
    JWT.decode(token, secret, true, algorithm: ALGORITHM).first
  rescue JWT::DecodeError
    nil
  end

  def self.secret
    ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
  end
end
