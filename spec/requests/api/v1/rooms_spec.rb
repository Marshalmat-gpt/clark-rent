require 'rails_helper'

RSpec.describe 'Api::V1::Rooms', type: :request do
  let(:user)           { create(:user) }
  let(:other_user)     { create(:user) }
  let(:property)       { create(:property, user: user) }
  let(:other_property) { create(:property, user: other_user) }
  let(:room)           { create(:room, property: property) }
  let(:other_room)     { create(:room, property: other_property) }

  describe 'GET /api/v1/rooms' do
    it 'returns only rooms from current user properties' do
      room && other_room
      get '/api/v1/rooms', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |r| r['id'] }
      expect(ids).to include(room.id)
      expect(ids).not_to include(other_room.id)
    end

    it 'filters by property_id when provided' do
      other_property_of_user = create(:property, user: user)
      room2 = create(:room, property: other_property_of_user)
      room

      get '/api/v1/rooms', params: { property_id: property.id }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |r| r['id'] }
      expect(ids).to include(room.id)
      expect(ids).not_to include(room2.id)
    end

    it 'returns 404 when filtering by another user property_id' do
      get '/api/v1/rooms', params: { property_id: other_property.id }, headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/rooms' do
    let(:valid_params) do
      { room: { name: 'Studio', rent: '650.00', charges: '50.00',
                surface_area: '25.00', property_id: property.id } }
    end

    it 'creates a room in own property' do
      post '/api/v1/rooms', params: valid_params, headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Studio')
      expect(json['property_id']).to eq(property.id)
      expect(json['rent'].to_f).to eq(650.0)
    end

    it 'returns 404 when property belongs to another user' do
      post '/api/v1/rooms',
           params: { room: { name: 'X', rent: '500', property_id: other_property.id } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 when rent is missing' do
      post '/api/v1/rooms',
           params: { room: { name: 'X', property_id: property.id } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 when property_id is missing' do
      post '/api/v1/rooms',
           params: { room: { name: 'Studio', rent: '650.00' } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/rooms/:id' do
    it 'updates own room' do
      patch "/api/v1/rooms/#{room.id}",
            params: { room: { rent: '750.00' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['rent'].to_f).to eq(750.0)
    end

    it 'silently ignores property_id in update (room cannot be reassigned)' do
      another_property = create(:property, user: user)
      patch "/api/v1/rooms/#{room.id}",
            params: { room: { rent: '800.00', property_id: another_property.id } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(room.reload.property_id).to eq(property.id) # unchanged
    end

    it 'returns 404 for another user room' do
      patch "/api/v1/rooms/#{other_room.id}",
            params: { room: { rent: '1.00' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/rooms/:id' do
    it 'destroys own room' do
      delete "/api/v1/rooms/#{room.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(Room.exists?(room.id)).to be false
    end

    it 'returns 404 for another user room' do
      delete "/api/v1/rooms/#{other_room.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end
end
