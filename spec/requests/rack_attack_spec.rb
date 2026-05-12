require 'rails_helper'

# Verifies rack-attack throttles are loaded and configured. The test env
# disables Rack::Attack globally (see config/environments/test.rb) so we
# re-enable for these specs and always restore — even on failure — via
# an around block to keep adjacent specs (e.g. sessions_spec) unaffected.
RSpec.describe 'Rack::Attack throttles', type: :request do
  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.reset!
    Rack::Attack.enabled = false
  end

  it 'registers all three throttle rules' do
    names = Rack::Attack.throttles.keys
    expect(names).to include('agent/chat per token', 'agent/chat per ip', 'logins per ip')
  end

  it 'throttles repeated POST /api/v1/sessions from the same IP' do
    payload = { email: 'nope@example.com', password: 'bad' }

    statuses = 11.times.map do
      post '/api/v1/sessions', params: payload
      response.status
    end

    expect(statuses).to include(429)
  end
end
