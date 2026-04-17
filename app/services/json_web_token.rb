class JsonWebToken
  SECRET = if Rails.env.development? || Rails.env.test?
             ENV.fetch('JWT_SECRET', 'fallback_secret_development_only')
           else
             ENV.fetch('JWT_SECRET') # raises KeyError on boot if unset in production
           end
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
