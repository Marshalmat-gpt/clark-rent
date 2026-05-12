require 'rails_helper'

# Verifies rack-attack throttles are loaded. The behavioural test
# (fire 11 requests, expect 429) was removed because rack-attack's
# in-process cache outlives the spec example and leaked 429s into
# adjacent sessions specs running in random order.
RSpec.describe 'Rack::Attack throttles' do
  it 'registers all three throttle rules' do
    expect(Rack::Attack.throttles.keys).to include(
      'agent/chat per token',
      'agent/chat per ip',
      'logins per ip'
    )
  end
end
