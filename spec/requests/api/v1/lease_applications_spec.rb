require 'rails_helper'

RSpec.describe 'Api::V1::LeaseApplications', type: :request do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:tenant2)  { create(:user, :tenant) }

  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  describe 'POST /api/v1/lease_applications' do
    it 'tenant applies to a room' do
      ActiveJob::Base.queue_adapter = :test
      expect do
        post '/api/v1/lease_applications',
             params: { lease_application: { room_id: room.id, message: 'Bonjour' } },
             headers: auth_headers(tenant)
      end.to have_enqueued_job(SendNotificationJob).with(
        hash_including(channel: 'email', recipient: landlord.email)
      )

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['tenant_id']).to eq(tenant.id)
      expect(json['room_id']).to eq(room.id)
      expect(json['status']).to eq('pending')
    end

    it 'rejects duplicate application' do
      create(:lease_application, tenant: tenant, room: room)
      post '/api/v1/lease_applications',
           params: { lease_application: { room_id: room.id } },
           headers: auth_headers(tenant)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/lease_applications' do
    it 'landlord sees applications on own rooms' do
      mine = create(:lease_application, tenant: tenant, room: room)
      get '/api/v1/lease_applications', headers: auth_headers(landlord)
      ids = JSON.parse(response.body).map { |a| a['id'] }
      expect(ids).to include(mine.id)
    end

    it 'tenant sees their own applications' do
      mine = create(:lease_application, tenant: tenant, room: room)
      get '/api/v1/lease_applications', headers: auth_headers(tenant)
      ids = JSON.parse(response.body).map { |a| a['id'] }
      expect(ids).to include(mine.id)
    end
  end

  describe 'PATCH /api/v1/lease_applications/:id/validate' do
    let(:application) { create(:lease_application, tenant: tenant, room: room) }

    it 'landlord approves an application' do
      ActiveJob::Base.queue_adapter = :test
      expect do
        patch "/api/v1/lease_applications/#{application.id}/validate",
              params: { decision: 'approved' },
              headers: auth_headers(landlord)
      end.to have_enqueued_job(SendNotificationJob).with(
        hash_including(channel: 'email', recipient: tenant.email)
      )

      expect(response).to have_http_status(:ok)
      expect(application.reload).to have_attributes(
        status: 'approved',
        validated_by_id: landlord.id
      )
    end

    it 'landlord rejects an application' do
      patch "/api/v1/lease_applications/#{application.id}/validate",
            params: { decision: 'rejected' },
            headers: auth_headers(landlord)

      expect(response).to have_http_status(:ok)
      expect(application.reload.status).to eq('rejected')
    end

    it '422 on bad decision' do
      patch "/api/v1/lease_applications/#{application.id}/validate",
            params: { decision: 'maybe' },
            headers: auth_headers(landlord)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'forbids non-owner landlord' do
      other = create(:user, role: 'landlord')
      patch "/api/v1/lease_applications/#{application.id}/validate",
            params: { decision: 'approved' },
            headers: auth_headers(other)
      # other landlord cannot see app via scope -> 404
      expect(response).to have_http_status(:not_found)
    end

    it 'forbids tenant validating' do
      patch "/api/v1/lease_applications/#{application.id}/validate",
            params: { decision: 'approved' },
            headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/lease_applications/:id' do
    it 'tenant deletes their own application' do
      app = create(:lease_application, tenant: tenant, room: room)
      delete "/api/v1/lease_applications/#{app.id}", headers: auth_headers(tenant)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids other tenant from deleting' do
      app = create(:lease_application, tenant: tenant, room: room)
      delete "/api/v1/lease_applications/#{app.id}", headers: auth_headers(tenant2)
      expect(response).to have_http_status(:not_found)
    end
  end
end
