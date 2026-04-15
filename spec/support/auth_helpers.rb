module AuthHelpers
  def auth_headers_for(user)
    payload = { user_id: user.id, role: user.role, exp: 30.days.from_now.to_i }
    token   = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
  end
end
