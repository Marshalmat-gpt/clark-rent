class JsonWebToken
  # rubocop:disable Rails/EnvironmentVariableAccess
  SECRET = if Rails.env.local?
               ENV.fetch('JWT_SECRET', 'fallback_secret_development_only')
             else
               ENV.fetch('JWT_SECRET') # raises KeyError on boot if unset in production
             end
  # rubocop:enable Rails/EnvironmentVariableAccess
  EXPIRY = 24.hours

  def self.encode(payload, exp = EXPIRY.from_now)
    payload[:exp] ||= exp.to_i
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: 'HS256').first
    decoded.with_indifferent_access
  end
end
