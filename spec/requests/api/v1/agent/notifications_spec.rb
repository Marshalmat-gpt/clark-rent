require 'rails_helper'

RSpec.describe 'Api::V1::Agent::Notifications', type: :request do
  let(:user) { create(:user) }

  before { ActiveJob::Base.queue_adapter = :test }

  it 'enqueues SendNotificationJob' do
    expect do
      post '/api/v1/agent/notifications/send',
           params: { channel: 'email', recipient: 'foo@example.com', payload: { subject: 'Hi' } },
           headers: auth_headers(user)
    end.to have_enqueued_job(SendNotificationJob).with(channel: 'email', recipient: 'foo@example.com',
                                                        payload: hash_including('subject' => 'Hi'))
    expect(response).to have_http_status(:accepted)
  end

  it '422 on bad channel' do
    post '/api/v1/agent/notifications/send',
         params: { channel: 'pigeon', recipient: 'x' },
         headers: auth_headers(user)
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
