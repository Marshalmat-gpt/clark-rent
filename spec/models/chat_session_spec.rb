require 'rails_helper'

RSpec.describe ChatSession, type: :model do
  subject(:session) { build(:chat_session) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
  end

  describe '#append_turn' do
    it 'appends a user message and an assistant reply' do
      session.save!
      session.append_turn('Mon loyer ?', 'Votre loyer est 800€.')
      expect(session.messages).to eq([
        { 'role' => 'user',      'content' => 'Mon loyer ?' },
        { 'role' => 'assistant', 'content' => 'Votre loyer est 800€.' }
      ])
    end

    it 'trims history to MAX_TURNS * 2 messages' do
      session.save!
      ChatSession::MAX_TURNS.times { |i| session.append_turn("q#{i}", "a#{i}") }
      session.append_turn('overflow', 'reply_overflow')
      expect(session.messages.length).to eq(ChatSession::MAX_TURNS * 2)
      expect(session.messages.last['content']).to eq('reply_overflow')
      expect(session.messages.first['content']).to eq('q1')
    end

    it 'casts non-string content to string' do
      session.save!
      session.append_turn(nil, 42)
      expect(session.messages).to eq([
        { 'role' => 'user',      'content' => '' },
        { 'role' => 'assistant', 'content' => '42' }
      ])
    end
  end

  describe '#history' do
    it 'returns the messages array' do
      session.messages = [{ 'role' => 'user', 'content' => 'test' }]
      expect(session.history).to eq(session.messages)
    end
  end
end
