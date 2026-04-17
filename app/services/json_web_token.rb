class JsonWebToken
  SECRET = ENV.fetch('JWT_SECRET', 'fallback_secret_development_only')
  EXPIRY = 24.hours

  def self.encode(payload, exp = EXPIRY.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: 'HS256').first
    HashWithIndifferentAccess.new(decoded)
  end
end
