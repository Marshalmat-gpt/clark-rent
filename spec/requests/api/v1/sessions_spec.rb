require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  let(:user) { create(:user, email: 'landlord@example.com', password: 'secret123') }

  describe 'POST /api/v1/sessions' do
    context 'with valid credentials' do
      it 'returns 200 with token and user' do
        post '/api/v1/sessions', params: { email: user.email, password: 'secret123' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('landlord@example.com')
        expect(json['user']).not_to have_key('password_digest')
      end
    end

    context 'with wrong password' do
      it 'returns 401' do
        post '/api/v1/sessions', params: { email: user.email, password: 'wrong' }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to be_present
      end
    end

    context 'with unknown email' do
      it 'returns 401' do
        post '/api/v1/sessions', params: { email: 'nobody@example.com', password: 'any' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/sessions/:id' do
    context 'when authenticated' do
      it 'returns 200 with message' do
        delete '/api/v1/sessions/1', headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to be_present
      end
    end

    context 'without token' do
      it 'returns 401' do
        delete '/api/v1/sessions/1'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
