require 'rails_helper'

RSpec.describe 'Api::V1::Leases', type: :request do
  let(:landlord)       { create(:user, role: 'landlord') }
  let(:other_landlord) { create(:user, role: 'landlord') }
  let(:tenant)         { create(:user, :tenant) }

  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  describe 'POST /api/v1/leases' do
    it 'landlord creates a lease on own room' do
      ActiveJob::Base.queue_adapter = :test
      expect do
        post '/api/v1/leases',
             params: { lease: { tenant_id: tenant.id, room_id: room.id,
                                start_date: Date.current, monthly_rent: 900,
                                monthly_charges: 30, deposit: 900 } },
             headers: auth_headers(landlord)
      end.to have_enqueued_job(SendNotificationJob).with(
        hash_including(channel: 'email', recipient: tenant.email)
      )

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['tenant_id']).to eq(tenant.id)
      expect(json['room_id']).to eq(room.id)
      expect(json['status']).to eq('active')
    end

    it 'forbids landlord on someone else room' do
      post '/api/v1/leases',
           params: { lease: { tenant_id: tenant.id, room_id: room.id,
                              start_date: Date.current, monthly_rent: 900 } },
           headers: auth_headers(other_landlord)

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 422 when invalid' do
      post '/api/v1/leases',
           params: { lease: { tenant_id: tenant.id, room_id: room.id,
                              start_date: Date.current, monthly_rent: -1 } },
           headers: auth_headers(landlord)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/leases' do
    it 'landlord sees leases on their rooms only' do
      mine    = create(:lease, room: room, tenant: tenant)
      other   = create(:lease,
                       room: create(:room, property: create(:property, user: other_landlord)),
                       tenant: tenant)

      get '/api/v1/leases', headers: auth_headers(landlord)
      ids = JSON.parse(response.body).map { |l| l['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end

    it 'tenant sees their own leases' do
      mine = create(:lease, room: room, tenant: tenant)
      get '/api/v1/leases', headers: auth_headers(tenant)
      ids = JSON.parse(response.body).map { |l| l['id'] }
      expect(ids).to include(mine.id)
    end

    it 'returns 401 without token' do
      get '/api/v1/leases'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/leases/:id/terminate' do
    it 'landlord terminates own lease' do
      ActiveJob::Base.queue_adapter = :test
      lease = create(:lease, room: room, tenant: tenant)
      expect do
        patch "/api/v1/leases/#{lease.id}/terminate", headers: auth_headers(landlord)
      end.to have_enqueued_job(SendNotificationJob).with(
        hash_including(channel: 'email', recipient: tenant.email)
      )

      expect(response).to have_http_status(:ok)
      expect(lease.reload.status).to eq('terminated')
      expect(lease.end_date).to eq(Date.current)
    end
  end

  describe 'DELETE /api/v1/leases/:id' do
    it 'landlord deletes own lease' do
      lease = create(:lease, room: room, tenant: tenant)
      delete "/api/v1/leases/#{lease.id}", headers: auth_headers(landlord)
      expect(response).to have_http_status(:ok)
      expect(Lease.exists?(lease.id)).to be false
    end
  end
end
