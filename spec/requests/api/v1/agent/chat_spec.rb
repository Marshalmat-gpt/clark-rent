require 'rails_helper'

RSpec.describe 'POST /api/v1/agent/chat', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  before do
    allow_any_instance_of(ClarkAgent::Orchestrator)
      .to receive(:chat)
      .and_return('Votre bail est actif.')
  end

  describe 'session lifecycle' do
    it 'creates a new session and returns session_id in response' do
      post '/api/v1/agent/chat', params: { message: 'Bonjour' }, headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['reply']).to eq('Votre bail est actif.')
      expect(body['session_id']).to be_a(Integer)
    end

    it 'persists user message and reply in the session' do
      post '/api/v1/agent/chat', params: { message: 'Mon loyer ?' }, headers: headers
      session = ChatSession.last
      expect(session.messages).to include(
        { 'role' => 'user',      'content' => 'Mon loyer ?' },
        { 'role' => 'assistant', 'content' => 'Votre bail est actif.' }
      )
    end

    it 'reuses existing session when valid session_id provided' do
      existing = create(:chat_session, user: user)
      post '/api/v1/agent/chat',
           params: { message: 'Deuxième question', session_id: existing.id },
           headers: headers
      body = JSON.parse(response.body)
      expect(body['session_id']).to eq(existing.id)
      expect(existing.reload.messages.length).to eq(2)
    end

    it 'creates a new session when session_id is not found' do
      post '/api/v1/agent/chat',
           params: { message: 'Bonjour', session_id: 999_999 },
           headers: headers
      body = JSON.parse(response.body)
      expect(body['session_id']).to be_a(Integer)
      expect(body['session_id']).not_to eq(999_999)
    end

    it 'prevents IDOR — cannot reuse another user session' do
      other = create(:user)
      other_session = create(:chat_session, user: other)
      post '/api/v1/agent/chat',
           params: { message: 'Hack', session_id: other_session.id },
           headers: headers
      body = JSON.parse(response.body)
      expect(body['session_id']).not_to eq(other_session.id)
      expect(other_session.reload.messages).to be_empty
    end

    it 'passes session history to Orchestrator' do
      existing = create(:chat_session, user: user,
                        messages: [{ 'role' => 'user',      'content' => 'Historique' },
                                   { 'role' => 'assistant', 'content' => 'Ok' }])
      expect_any_instance_of(ClarkAgent::Orchestrator)
        .to receive(:chat)
        .with('Nouvelle question', history: existing.messages)
        .and_return('Réponse')
      post '/api/v1/agent/chat',
           params: { message: 'Nouvelle question', session_id: existing.id },
           headers: headers
    end
  end

  describe 'error handling' do
    it 'returns 400 when message param is missing' do
      post '/api/v1/agent/chat', params: {}, headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 502 and does not save a new session when Orchestrator raises' do
      allow_any_instance_of(ClarkAgent::Orchestrator)
        .to receive(:chat)
        .and_raise(StandardError, 'API down')
      expect {
        post '/api/v1/agent/chat', params: { message: 'Test' }, headers: headers
      }.not_to change(ChatSession, :count)
      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
