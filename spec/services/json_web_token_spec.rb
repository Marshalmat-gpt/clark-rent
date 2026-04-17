require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:payload) { { user_id: 42 } }

  describe '.encode' do
    it 'returns a three-part JWT string' do
      token = JsonWebToken.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'embeds the user_id in the payload' do
      token = JsonWebToken.encode(payload)
      decoded = JsonWebToken.decode(token)
      expect(decoded[:user_id]).to eq(42)
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      token = JsonWebToken.encode(payload)
      decoded = JsonWebToken.decode(token)
      expect(decoded[:user_id]).to eq(payload[:user_id])
    end

    it 'raises JWT::DecodeError for a tampered token' do
      expect { JsonWebToken.decode('bad.token.here') }.to raise_error(JWT::DecodeError)
    end

    it 'raises JWT::DecodeError for an expired token' do
      expired = JsonWebToken.encode(payload, 1.second.ago)
      expect { JsonWebToken.decode(expired) }.to raise_error(JWT::DecodeError)
    end
  end
end
