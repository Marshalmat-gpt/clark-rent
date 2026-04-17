require 'rails_helper'

RSpec.describe 'Api::V1::Properties', type: :request do
  let(:user)           { create(:user) }
  let(:other_user)     { create(:user) }
  let(:property)       { create(:property, user: user) }
  let(:other_property) { create(:property, user: other_user) }

  describe 'GET /api/v1/properties' do
    it 'returns only current user properties' do
      property && other_property
      get '/api/v1/properties', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |p| p['id'] }
      expect(ids).to include(property.id)
      expect(ids).not_to include(other_property.id)
    end

    it 'returns 401 without token' do
      get '/api/v1/properties'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/properties/:id' do
    it 'returns own property' do
      get "/api/v1/properties/#{property.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(property.id)
      expect(json['name']).to eq(property.name)
      expect(json['user_id']).to eq(user.id)
    end

    it 'returns 404 for another user property' do
      get "/api/v1/properties/#{other_property.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/properties' do
    it 'creates a property owned by current user' do
      post '/api/v1/properties',
           params: { property: { name: 'Mon Appartement', address: '1 Rue de Rivoli, Paris' } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Mon Appartement')
      expect(json['user_id']).to eq(user.id)
    end

    it 'returns 422 when name is missing' do
      post '/api/v1/properties',
           params: { property: { address: '1 Rue de Rivoli, Paris' } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_a(Array)
    end
  end

  describe 'PATCH /api/v1/properties/:id' do
    it 'updates own property' do
      patch "/api/v1/properties/#{property.id}",
            params: { property: { name: 'Renamed' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['name']).to eq('Renamed')
    end

    it 'returns 404 for another user property' do
      patch "/api/v1/properties/#{other_property.id}",
            params: { property: { name: 'Hijacked' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/properties/:id' do
    it 'destroys own property and returns ok' do
      delete "/api/v1/properties/#{property.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(Property.exists?(property.id)).to be false
    end

    it 'returns 404 for another user property' do
      delete "/api/v1/properties/#{other_property.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/properties/:id/documents' do
    it 'returns empty documents array (Phase 3 stub)' do
      get "/api/v1/properties/#{property.id}/documents", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['documents']).to eq([])
    end
  end
end
