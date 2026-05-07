require 'rails_helper'

RSpec.describe 'Api::V1::Agent::Chat', type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ClarkAgent::Orchestrator).to receive(:chat).and_return('Bonjour Mathieu.')
  end

  it 'returns the orchestrator reply' do
    post '/api/v1/agent/chat',
         params: { message: 'Salut' },
         headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['reply']).to eq('Bonjour Mathieu.')
  end

  it '400 when message missing' do
    post '/api/v1/agent/chat', params: {}, headers: auth_headers(user)
    expect(response).to have_http_status(:bad_request)
  end

  it '502 when orchestrator raises' do
    allow_any_instance_of(ClarkAgent::Orchestrator).to receive(:chat).and_raise(StandardError, 'boom')
    post '/api/v1/agent/chat',
         params: { message: 'Salut' },
         headers: auth_headers(user)
    expect(response).to have_http_status(:bad_gateway)
  end
end
