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
        { 'type' => 'tool_use', 'id' => 'tool_1', 'name' => 'get_user_context', 'input' => {} }
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
      'content' => [{ 'type' => 'tool_use', 'id' => 'tool_loop', 'name' => 'get_user_context', 'input' => {} }]
    }
    allow(fake_client).to receive(:messages).and_return(looping)

    expect(orchestrator.chat('Boucle')).to include('limite d\'itérations')
  end
end
