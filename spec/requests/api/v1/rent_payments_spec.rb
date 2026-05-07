require 'rails_helper'

RSpec.describe 'Api::V1::RentPayments', type: :request do
  let(:landlord)       { create(:user, role: 'landlord') }
  let(:other_landlord) { create(:user, role: 'landlord') }
  let(:tenant)         { create(:user, :tenant) }
  let(:property)       { create(:property, user: landlord) }
  let(:room)           { create(:room, property: property) }
  let(:lease)          { create(:lease, room: room, tenant: tenant) }

  describe 'POST /api/v1/rent_payments' do
    it 'landlord generates payments for own lease' do
      post '/api/v1/rent_payments',
           params: { lease_id: lease.id, months: 3 },
           headers: auth_headers(landlord)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
      expect(json.first['lease_id']).to eq(lease.id)
    end

    it 'forbids landlord on someone else lease' do
      post '/api/v1/rent_payments',
           params: { lease_id: lease.id, months: 3 },
           headers: auth_headers(other_landlord)
      expect(response).to have_http_status(:not_found)
    end

    it '400 when lease_id missing' do
      post '/api/v1/rent_payments',
           params: {},
           headers: auth_headers(landlord)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET /api/v1/rent_payments' do
    let!(:mine)  { create(:rent_payment, lease: lease, tenant: tenant) }
    let!(:other) do
      other_lease = create(:lease,
                           room: create(:room, property: create(:property, user: other_landlord)),
                           tenant: create(:user, :tenant))
      create(:rent_payment, lease: other_lease, tenant: other_lease.tenant)
    end

    it 'tenant sees own payments only' do
      get '/api/v1/rent_payments', headers: auth_headers(tenant)
      ids = JSON.parse(response.body).map { |p| p['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end

    it 'landlord sees own properties payments only' do
      get '/api/v1/rent_payments', headers: auth_headers(landlord)
      ids = JSON.parse(response.body).map { |p| p['id'] }
      expect(ids).to include(mine.id)
      expect(ids).not_to include(other.id)
    end

    it 'filters by status when provided' do
      paid = create(:rent_payment, lease: lease, tenant: tenant, status: 'paid', paid_at: Date.current)
      get '/api/v1/rent_payments', params: { status: 'paid' }, headers: auth_headers(landlord)
      ids = JSON.parse(response.body).map { |p| p['id'] }
      expect(ids).to include(paid.id)
      expect(ids).not_to include(mine.id)
    end
  end

  describe 'PATCH /api/v1/rent_payments/:id/mark_paid' do
    let(:payment) { create(:rent_payment, lease: lease, tenant: tenant) }

    it 'landlord marks payment as paid' do
      patch "/api/v1/rent_payments/#{payment.id}/mark_paid",
            params: { payment_method: 'virement' },
            headers: auth_headers(landlord)

      expect(response).to have_http_status(:ok)
      expect(payment.reload).to have_attributes(status: 'paid', payment_method: 'virement')
    end

    it 'forbids tenant from marking paid' do
      patch "/api/v1/rent_payments/#{payment.id}/mark_paid",
            params: {},
            headers: auth_headers(tenant)
      # tenant scope finds the payment but landlord_owner? returns false -> 403
      expect(response).to have_http_status(:forbidden)
    end
  end
end
