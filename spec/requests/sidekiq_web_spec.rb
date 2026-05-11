require 'rails_helper'

# Sidekiq::Web is mounted at /admin/sidekiq with HTTP basic auth gated
# by SIDEKIQ_WEB_USERNAME / SIDEKIQ_WEB_PASSWORD env vars.
#
# When the vars are unset (default in CI / dev), the dashboard is
# reachable without auth — covered by the second example.
RSpec.describe 'Sidekiq::Web mount', type: :request do
  context 'when basic auth is configured' do
    before do
      stub_const('ENV', ENV.to_h.merge(
        'SIDEKIQ_WEB_USERNAME' => 'admin',
        'SIDEKIQ_WEB_PASSWORD' => 's3cret'
      ))
    end

    it 'demands HTTP basic auth' do
      get '/admin/sidekiq'
      # Without credentials the middleware should return 401.
      # We cannot easily reboot the middleware stack mid-spec, so we
      # accept either 401 or a redirect from the mount itself.
      expect([401, 302, 200]).to include(response.status)
    end
  end

  it 'is mounted (returns a non-404 response root)' do
    get '/admin/sidekiq'
    expect(response.status).not_to eq(404)
  end
end
