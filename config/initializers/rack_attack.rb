class Rack::Attack
  # Throttle login attempts by IP: 5 per 60s
  throttle('login/ip', limit: 5, period: 60) do |req|
    req.ip if req.path == '/api/v1/sessions' && req.post?
  end

  # Throttle login attempts by email: 5 per 60s
  throttle('login/email', limit: 5, period: 60) do |req|
    if req.path == '/api/v1/sessions' && req.post?
      req.params['email']&.downcase&.gsub(/\s+/, '')
    end
  end

  self.throttled_responder = lambda do |_env|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Too many requests. Please try again later.' }.to_json]
    ]
  end
end
