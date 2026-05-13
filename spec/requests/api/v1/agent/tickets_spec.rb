require 'rails_helper'

RSpec.describe 'Api::V1::Agent::Tickets', type: :request do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }

  describe 'POST /api/v1/agent/tickets' do
    before { create(:lease, room: room, tenant: tenant, status: 'active') }

    it 'tenant opens a ticket' do
      ActiveJob::Base.queue_adapter = :test
      expect do
        post '/api/v1/agent/tickets',
             params: { ticket: { category: 'plomberie', description: 'Robinet qui fuit' } },
             headers: auth_headers(tenant)
      end.to have_enqueued_job(SendNotificationJob).with(
        hash_including(channel: 'email', recipient: landlord.email)
      )

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['category']).to eq('plomberie')
      expect(json['tenant_id']).to eq(tenant.id)
      expect(json['status']).to eq('open')
    end

    it '422 when description missing' do
      post '/api/v1/agent/tickets',
           params: { ticket: { category: 'plomberie' } },
           headers: auth_headers(tenant)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/agent/tickets' do
    it 'tenant sees only their own' do
      mine  = create(:ticket, tenant: tenant, property: property)
      other = create(:ticket, tenant: create(:user, :tenant), property: property)

      get '/api/v1/agent/tickets', headers: auth_headers(tenant)
      ids = JSON.parse(response.body).map { |t| t['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end

    it 'landlord sees tickets on own properties' do
      mine          = create(:ticket, tenant: tenant, property: property)
      other_prop    = create(:property, user: create(:user, role: 'landlord'))
      other         = create(:ticket, tenant: tenant, property: other_prop)

      get '/api/v1/agent/tickets', headers: auth_headers(landlord)
      ids = JSON.parse(response.body).map { |t| t['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end
  end
  describe 'PATCH /api/v1/agent/tickets/:id/resolve' do
    let!(:property) { create(:property, user: landlord) }
    let(:ticket)    { create(:ticket, tenant: tenant, property: property, status: 'open') }

    it 'landlord resolves own ticket + enqueues TicketMailer.resolved to tenant' do
      ActiveJob::Base.queue_adapter = :test

      expect do
        patch "/api/v1/agent/tickets/#{ticket.id}/resolve", headers: auth_headers(landlord)
      end.to have_enqueued_job(SendNotificationJob).with(
        hash_including(
          channel: 'email',
          recipient: tenant.email,
          payload: hash_including(mailer: 'TicketMailer', action: 'resolved')
        )
      )

      expect(response).to have_http_status(:ok)
      expect(ticket.reload).to have_attributes(status: 'resolved')
      expect(ticket.resolved_at).not_to be_nil
    end

    it 'forbids landlord on someone else property' do
      other_landlord = create(:user, role: 'landlord')
      patch "/api/v1/agent/tickets/#{ticket.id}/resolve", headers: auth_headers(other_landlord)
      # other landlord scope returns empty -> 404 via scoped_tickets.find
      expect(response).to have_http_status(:not_found)
    end

    it 'forbids tenant from resolving their own ticket' do
      patch "/api/v1/agent/tickets/#{ticket.id}/resolve", headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
