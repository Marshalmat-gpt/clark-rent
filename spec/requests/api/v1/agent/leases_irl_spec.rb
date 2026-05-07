require 'rails_helper'

RSpec.describe 'Api::V1::Agent::Leases#irl', type: :request do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }
  let(:lease)    { create(:lease, room: room, tenant: tenant, monthly_rent: 850) }

  it 'returns the revised rent' do
    get "/api/v1/agent/leases/#{lease.id}/irl",
        params: { base_irl: 136.27, current_irl: 142.06 },
        headers: auth_headers(landlord)

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json['revised_rent']).to be_within(0.05).of(886.13)
  end

  it '400 when base_irl missing' do
    get "/api/v1/agent/leases/#{lease.id}/irl",
        params: { current_irl: 142.06 },
        headers: auth_headers(landlord)
    expect(response).to have_http_status(:bad_request)
  end
end
