require 'rails_helper'

RSpec.describe TwilioSms do
  describe '.configured?' do
    it 'is false when env vars missing' do
      ClimateControl.modify(TWILIO_ACCOUNT_SID: nil, TWILIO_AUTH_TOKEN: nil, TWILIO_FROM: nil) do
        expect(described_class.configured?).to be false
      end
    rescue NameError
      # ClimateControl not present — fall back to direct ENV stubbing
      stub_const('ENV', ENV.to_h.except('TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN', 'TWILIO_FROM'))
      expect(described_class.configured?).to be false
    end

    it 'is true when all three are set' do
      stub_const('ENV', ENV.to_h.merge(
        'TWILIO_ACCOUNT_SID' => 'AC123',
        'TWILIO_AUTH_TOKEN'  => 'secret',
        'TWILIO_FROM'        => '+33611111111'
      ))
      expect(described_class.configured?).to be true
    end
  end

  describe '.send' do
    it 'raises ConfigurationError when TWILIO_FROM is blank' do
      stub_const('ENV', ENV.to_h.merge('TWILIO_FROM' => ''))
      expect do
        described_class.send(to: '+33611111111', body: 'hi')
      end.to raise_error(TwilioSms::ConfigurationError)
    end
  end
end
