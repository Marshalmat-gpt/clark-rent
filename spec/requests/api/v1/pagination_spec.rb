require 'rails_helper'

# Cross-controller pagination behaviour. Uses /api/v1/properties as the
# canonical index since it has the simplest scope (current_user.properties).
RSpec.describe 'Pagination', type: :request do
  let(:user) { create(:user, role: 'landlord') }

  before do
    30.times { create(:property, user: user) }
  end

  it 'defaults to 25 rows per page and sets pagination headers' do
    get '/api/v1/properties', headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).size).to eq(25)
    expect(response.headers['X-Total-Count']).to eq('30')
    expect(response.headers['X-Page']).to eq('1')
    expect(response.headers['X-Per-Page']).to eq('25')
    expect(response.headers['X-Total-Pages']).to eq('2')
  end

  it 'returns the second page on ?page=2' do
    get '/api/v1/properties', params: { page: 2 }, headers: auth_headers(user)

    expect(JSON.parse(response.body).size).to eq(5)
    expect(response.headers['X-Page']).to eq('2')
  end

  it 'honours ?per_page' do
    get '/api/v1/properties', params: { per_page: 10 }, headers: auth_headers(user)

    expect(JSON.parse(response.body).size).to eq(10)
    expect(response.headers['X-Per-Page']).to eq('10')
    expect(response.headers['X-Total-Pages']).to eq('3')
  end

  it 'caps per_page at 100' do
    get '/api/v1/properties', params: { per_page: 500 }, headers: auth_headers(user)

    expect(response.headers['X-Per-Page']).to eq('100')
  end

  it 'treats invalid page/per_page as defaults' do
    get '/api/v1/properties', params: { page: -1, per_page: 'foo' }, headers: auth_headers(user)

    expect(response.headers['X-Page']).to eq('1')
    expect(response.headers['X-Per-Page']).to eq('25')
  end
end
