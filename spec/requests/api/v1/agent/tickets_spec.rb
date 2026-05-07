require 'rails_helper'

RSpec.describe 'Api::V1::Agent::Tickets', type: :request do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  describe 'POST /api/v1/agent/tickets' do
    it 'tenant opens a ticket' do
      post '/api/v1/agent/tickets',
           params: { ticket: { room_id: room.id, title: 'Fuite', description: 'Robinet' } },
           headers: auth_headers(tenant)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Fuite')
      expect(json['reporter_id']).to eq(tenant.id)
      expect(json['status']).to eq('open')
    end

    it '422 when title missing' do
      post '/api/v1/agent/tickets',
           params: { ticket: { room_id: room.id } },
           headers: auth_headers(tenant)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/agent/tickets' do
    it 'tenant sees only their own' do
      mine  = create(:ticket, reporter: tenant, room: room)
      other = create(:ticket, reporter: create(:user, :tenant), room: room)

      get '/api/v1/agent/tickets', headers: auth_headers(tenant)
      ids = JSON.parse(response.body).map { |t| t['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end

    it 'landlord sees tickets on own rooms' do
      mine  = create(:ticket, reporter: tenant, room: room)
      other_room = create(:room, property: create(:property, user: create(:user, role: 'landlord')))
      other = create(:ticket, reporter: tenant, room: other_room)

      get '/api/v1/agent/tickets', headers: auth_headers(landlord)
      ids = JSON.parse(response.body).map { |t| t['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end
  end
end
