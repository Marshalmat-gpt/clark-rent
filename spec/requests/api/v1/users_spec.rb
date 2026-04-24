require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }

  describe 'POST /api/v1/users (registration)' do
    let(:valid_params) do
      { email: 'new@example.com', password: 'password123',
        first_name: 'Jane', last_name: 'Doe', role: 'landlord' }
    end

    context 'with valid params' do
      it 'creates a user and returns token + user' do
        post '/api/v1/users', params: valid_params

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('new@example.com')
        expect(json['user']).not_to have_key('password_digest')
        expect(User.count).to eq(1)
      end
    end

    context 'with duplicate email' do
      it 'returns 422 with errors array' do
        create(:user, email: 'new@example.com')
        post '/api/v1/users', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to be_a(Array)
      end
    end

    context 'with missing password' do
      it 'returns 422' do
        post '/api/v1/users', params: { email: 'x@x.com', first_name: 'A', last_name: 'B' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /api/v1/users' do
    it 'returns all users for authenticated user' do
      user && other_user
      get '/api/v1/users', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(2)
    end

    it 'returns 401 without token' do
      get '/api/v1/users'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'returns the user' do
      get "/api/v1/users/#{user.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(user.id)
      expect(json['email']).to eq(user.email)
    end

    it 'returns 404 for non-existent user' do
      get '/api/v1/users/99999', headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    context 'when updating own account' do
      it 'updates and returns updated user' do
        patch "/api/v1/users/#{user.id}",
              params: { first_name: 'Updated' },
              headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['first_name']).to eq('Updated')
      end
    end

    context 'when updating another user' do
      it 'returns 403 Forbidden' do
        patch "/api/v1/users/#{other_user.id}",
              params: { first_name: 'Hacked' },
              headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
        expect(other_user.reload.first_name).not_to eq('Hacked')
      end
    end
  end

  describe 'DELETE /api/v1/users/:id' do
    context 'when deleting own account' do
      it 'deletes the account and returns ok' do
        delete "/api/v1/users/#{user.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(User.exists?(user.id)).to be false
      end
    end

    context 'when deleting another user' do
      it 'returns 403 Forbidden' do
        delete "/api/v1/users/#{other_user.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
        expect(User.exists?(other_user.id)).to be true
      end
    end
  end
end
