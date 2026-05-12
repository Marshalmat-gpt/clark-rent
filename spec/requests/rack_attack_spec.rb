require 'rails_helper'

# Verifies rack-attack throttles are loaded and configured. The test env
# disables Rack::Attack globally (see config/environments/test.rb) so we
# re-enable for these specs and re-disable in an after block.
RSpec.describe 'Rack::Attack throttles', type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after { Rack::Attack.enabled = false }

  it 'registers all three throttle rules' do
    names = Rack::Attack.throttles.keys
    expect(names).to include('agent/chat per token', 'agent/chat per ip', 'logins per ip')
  end

  it 'throttles repeated POST /api/v1/sessions from the same IP' do
    # logins per ip = 10 per 5 minutes — fire 11 requests
    payload = { email: 'nope@example.com', password: 'bad' }

    11.times.map do
      post '/api/v1/sessions', params: payload
      response.status
    end => statuses

    # At least one request must have been rejected with 429.
    expect(statuses).to include(429)
  end
end
