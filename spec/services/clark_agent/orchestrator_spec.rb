require 'rails_helper'

RSpec.describe ClarkAgent::Orchestrator do
  let(:user)         { create(:user, :tenant) }
  let(:fake_client)  { instance_double(Anthropic::Client) }
  let(:orchestrator) { described_class.new(user: user) }

  before do
    allow(Anthropic::Client).to receive(:new).and_return(fake_client)
  end

  it 'returns the assistant text when stop_reason is end_turn' do
    allow(fake_client).to receive(:messages).and_return(
      'stop_reason' => 'end_turn',
      'content' => [{ 'type' => 'text', 'text' => 'Bonjour Mathieu.' }]
    )

    expect(orchestrator.chat('Salut')).to eq('Bonjour Mathieu.')
  end

  it 'runs a tool, sends the result back, and returns the final answer' do
    first  = {
      'stop_reason' => 'tool_use',
      'content' => [
        { 'type' => 'tool_use', 'id' => 'tool_1', 'name' => 'get_my_lease', 'input' => {} }
      ]
    }
    second = {
      'stop_reason' => 'end_turn',
      'content' => [{ 'type' => 'text', 'text' => 'Tu as 0 ticket ouvert.' }]
    }

    call = 0
    allow(fake_client).to receive(:messages) do
      call += 1
      call == 1 ? first : second
    end

    expect(orchestrator.chat('Combien de tickets ?')).to eq('Tu as 0 ticket ouvert.')
  end

  it 'falls back when tools loop exceeds MAX_ITERATIONS' do
    looping = {
      'stop_reason' => 'tool_use',
      'content' => [{ 'type' => 'tool_use', 'id' => 'tool_loop', 'name' => 'get_my_lease', 'input' => {} }]
    }
    allow(fake_client).to receive(:messages).and_return(looping)

    expect(orchestrator.chat('Boucle')).to include('limite d\'itérations')
  end

  describe '#chat tool dispatch' do
    let(:user) { build_stubbed(:user, role: 'tenant', first_name: 'Alice') }
    let(:orchestrator) { described_class.new(user: user) }

    let(:tool_use_response) do
      {
        'stop_reason' => 'tool_use',
        'content' => [
          { 'type' => 'tool_use', 'id' => 'toolu_01', 'name' => 'get_my_lease', 'input' => {} }
        ]
      }
    end
    let(:end_turn_response) do
      { 'stop_reason' => 'end_turn', 'content' => [{ 'type' => 'text', 'text' => 'Votre bail est actif.' }] }
    end

    before do
      allow(orchestrator).to receive_message_chain(:client, :messages)
        .and_return(tool_use_response, end_turn_response)
      allow(ClarkAgent::ToolExecutor).to receive(:execute).and_return({ content: { id: 1 } })
    end

    it 'dispatches tool call to ToolExecutor' do
      orchestrator.chat('Montre mon bail')
      expect(ClarkAgent::ToolExecutor).to have_received(:execute).with(
        name: 'get_my_lease',
        input: {},
        user: user,
        _role: user.role
      )
    end

    it 'strips PROTECTED_TOOL_KEYS before dispatching' do
      injected_response = {
        'stop_reason' => 'tool_use',
        'content' => [
          {
            'type' => 'tool_use',
            'id' => 'toolu_02',
            'name' => 'get_my_lease',
            'input' => { 'user' => 'injected', 'role' => 'admin', 'current_user' => 'hacked', 'limit' => 5 }
          }
        ]
      }
      allow(orchestrator).to receive_message_chain(:client, :messages)
        .and_return(injected_response, end_turn_response)

      orchestrator.chat('Montre mon bail')

      expect(ClarkAgent::ToolExecutor).to have_received(:execute).with(
        name: 'get_my_lease',
        input: { 'limit' => 5 },
        user: user,
        _role: user.role
      )
    end
  end
end
