require 'rails_helper'

# Sidekiq::Web is mounted at /admin/sidekiq with HTTP basic auth gated
# by SIDEKIQ_WEB_USERNAME / SIDEKIQ_WEB_PASSWORD env vars.
#
# We only verify the route is wired — actually rendering the dashboard
# in-process requires session middleware that the Rails API mode does
# not include, and is exercised separately in production behind real
# auth.
RSpec.describe 'Sidekiq::Web mount', type: :routing do
  it 'is wired at /admin/sidekiq' do
    expect(get: '/admin/sidekiq').to be_routable
  end
end
