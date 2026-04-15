require 'rails_helper'

RSpec.describe 'Agent chat endpoint', type: :request do
  let(:owner)     { create(:user, :owner) }
  let(:tenant)    { create(:user, :tenant) }
  let(:property)  { create(:property, owner: owner) }
  let(:lease)     { create(:property_lease, property: property, status: 'open') }

  before do
    create(:lease_application, property_lease: lease, applicant: tenant, status: 'approved')
  end

  describe 'POST /api/v1/agent/chat' do
    context 'as tenant' do
      it 'returns a reply and empty actions for a simple question' do
        # On stub l'appel Anthropic pour ne pas consommer de crédits en CI
        fake_response = double(
          content:     [double(type: 'text', text: 'Votre loyer est de 620€.')],
          stop_reason: 'end_turn'
        )
        allow_any_instance_of(Anthropic::Client)
          .to receive(:messages).and_return(fake_response)

        post '/api/v1/agent/chat',
             params:  { message: 'Quel est mon loyer ?' }.to_json,
             headers: auth_headers_for(tenant)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['reply']).to be_present
        expect(json['actions']).to be_an(Array)
        expect(json['history']).to be_an(Array)
      end
    end

    context 'without token' do
      it 'returns 401' do
        post '/api/v1/agent/chat',
             params:  { message: 'Test' }.to_json,
             headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/agent/context' do
    context 'as owner' do
      it 'returns owner context with property count' do
        get '/api/v1/agent/context', headers: auth_headers_for(owner)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['role']).to eq('owner')
        expect(json['property_count']).to eq(1)
      end
    end

    context 'as tenant' do
      it 'returns tenant context with lease info' do
        get '/api/v1/agent/context', headers: auth_headers_for(tenant)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['role']).to eq('tenant')
        expect(json['rent']).to eq('620.0')
      end
    end
  end
end
