require 'rails_helper'

RSpec.describe 'GET /health', type: :request do
  it 'returns 200 + ok status with all subsystem keys' do
    get '/health'

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json).to include('status' => 'ok', 'env' => 'test')
    expect(json['db']).to be(true)
    expect(json).to have_key('redis')
    expect(json).to have_key('sidekiq')
    expect(json['sidekiq']).to include('available')
  end

  it 'returns 503 when the database is unreachable' do
    allow_any_instance_of(HealthController).to receive(:db_alive?).and_return(false)

    get '/health'
    expect(response).to have_http_status(:service_unavailable)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end
end
