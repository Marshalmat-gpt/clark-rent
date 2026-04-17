module RequestHelpers
  # Generates Authorization header with a valid JWT for the given user.
  # Usage in request specs:
  #   get '/api/v1/properties', headers: auth_headers(user)
  def auth_headers(user)
    payload = {
      user_id: user.id,
      exp: 24.hours.from_now.to_i
    }
    token = JWT.encode(payload, ENV.fetch('JWT_SECRET', 'test_jwt_secret'), 'HS256')
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
