require 'rails_helper'

# End-to-end spec for POST /api/v1/agent/chat
#
# Stubs Anthropic::Client at the constructor boundary so the controller +
# orchestrator + ToolRegistry path is exercised without hitting the API.
# Verifies:
#   * a single end_turn response flows back as JSON `reply`
#   * a tool_use round-trip actually executes the tool against the DB and
#     completes with a final assistant text
RSpec.describe 'Api::V1::Agent::Chat (e2e)', type: :request do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant) }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }
  let(:fake_client) { instance_double(Anthropic::Client) }

  before do
    allow(Anthropic::Client).to receive(:new).and_return(fake_client)
  end

  describe 'simple reply' do
    it 'returns the assistant text on end_turn' do
      allow(fake_client).to receive(:messages).and_return(
        'stop_reason' => 'end_turn',
        'content' => [{ 'type' => 'text', 'text' => 'Bonjour, comment puis-je aider ?' }]
      )

      post '/api/v1/agent/chat',
           params: { message: 'Bonjour' },
           headers: auth_headers(tenant)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['reply']).to eq('Bonjour, comment puis-je aider ?')
    end
  end

  describe 'tool_use round-trip with create_ticket' do
    before { create(:lease, room: room, tenant: tenant, status: 'active') }

    it 'executes the tool, persists the ticket, then returns the final answer' do
      tool_use_response = {
        'stop_reason' => 'tool_use',
        'content' => [{
          'type' => 'tool_use',
          'id' => 'tu_1',
          'name' => 'create_ticket',
          'input' => { 'category' => 'plomberie', 'description' => 'Robinet qui fuit', 'priority' => 'urgent' }
        }]
      }
      end_turn_response = {
        'stop_reason' => 'end_turn',
        'content' => [{ 'type' => 'text', 'text' => 'Ticket créé avec succès.' }]
      }

      call_count = 0
      allow(fake_client).to receive(:messages) do |params|
        call_count += 1
        # First call should include tool specs; second call must include
        # the assistant tool_use block + a tool_result back to the model.
        expect(params[:parameters][:tools]).to be_an(Array) if call_count == 1
        if call_count == 2
          last_messages = params[:parameters][:messages]
          expect(last_messages.last[:role]).to eq('user')
          expect(last_messages.last[:content].first[:type]).to eq('tool_result')
        end
        call_count == 1 ? tool_use_response : end_turn_response
      end

      expect do
        post '/api/v1/agent/chat',
             params: { message: 'Crée un ticket pour le robinet' },
             headers: auth_headers(tenant)
      end.to change(Ticket, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['reply']).to eq('Ticket créé avec succès.')

      ticket = Ticket.last
      expect(ticket).to have_attributes(
        category: 'plomberie',
        description: 'Robinet qui fuit',
        priority: 'urgent',
        tenant_id: tenant.id,
        property_id: property.id
      )
    end
  end

  describe 'orchestrator failure' do
    it 'returns 502 when Anthropic raises' do
      allow(fake_client).to receive(:messages).and_raise(StandardError, 'upstream down')

      post '/api/v1/agent/chat',
           params: { message: 'Salut' },
           headers: auth_headers(tenant)

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
