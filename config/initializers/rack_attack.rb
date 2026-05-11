# Rack::Attack — request throttling
#
# Requires the rack-attack gem. Add to Gemfile:
#   gem 'rack-attack'
#
# Agent chat is throttled per authenticated token (20 req/min) and per IP (30 req/min)
# to prevent Anthropic API cost exhaustion and brute-force abuse.

return unless defined?(Rack::Attack)

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
