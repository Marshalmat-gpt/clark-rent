# Rack::Attack — request throttling
#
# Agent chat is throttled per authenticated token (20 req/min) and per IP (30 req/min)
# to prevent Anthropic API cost exhaustion and brute-force abuse.
#
# Login brute-force protection (10 attempts / 5 min per IP) supplements the
# Redis-backed check_login_rate_limit! in Api::V1::SessionsController.

Rack::Attack.throttle('agent/chat per token', limit: 20, period: 60) do |req|
  req.env['HTTP_AUTHORIZATION']&.split(' ')&.last if req.path == '/api/v1/agent/chat'
end

Rack::Attack.throttle('agent/chat per ip', limit: 30, period: 60) do |req|
  req.ip if req.path == '/api/v1/agent/chat'
end

Rack::Attack.throttle('logins per ip', limit: 10, period: 300) do |req|
  req.ip if req.path == '/api/v1/sessions' && req.post?
end

Rack::Attack.throttled_responder = lambda do |_req|
  [429, { 'Content-Type' => 'application/json' }, ['{"error":"Too many requests"}']]
end
