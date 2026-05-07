require 'rails_helper'

RSpec.describe SendNotificationJob, type: :job do
  let(:landlord) { create(:user, role: 'landlord', email: 'landlord@example.com') }
  let(:tenant)   { create(:user, :tenant, email: 'tenant@example.com') }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }
  let(:lease)    { create(:lease, room: room, tenant: tenant) }

  before { ActionMailer::Base.deliveries.clear }

  describe 'email channel' do
    it 'invokes the named mailer with positional arg' do
      described_class.new.perform(
        channel: 'email',
        recipient: 'tenant@example.com',
        payload: { 'mailer' => 'LeaseMailer', 'action' => 'signed', 'args' => [lease.id] }
      )

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.subject).to include('signé')
    end

    it 'invokes the named mailer with another positional arg' do
      described_class.new.perform(
        channel: 'email',
        recipient: 'tenant@example.com',
        payload: { 'mailer' => 'LeaseMailer', 'action' => 'terminated', 'args' => [lease.id] }
      )

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.subject).to include('Fin')
    end
  end

  describe 'sms channel' do
    it 'logs and skips when Twilio not configured' do
      stub_const('ENV', ENV.to_h.merge('TWILIO_ACCOUNT_SID' => '', 'TWILIO_AUTH_TOKEN' => '', 'TWILIO_FROM' => ''))
      expect(Rails.logger).to receive(:info).with(/skipped/i)
      described_class.new.perform(channel: 'sms', recipient: '+336', payload: { 'body' => 'Hi' })
    end

    it 'calls TwilioSms.send when configured' do
      stub_const('ENV', ENV.to_h.merge(
        'TWILIO_ACCOUNT_SID' => 'AC123',
        'TWILIO_AUTH_TOKEN'  => 'secret',
        'TWILIO_FROM'        => '+33611111111'
      ))
      expect(TwilioSms).to receive(:send).with(to: '+33612345678', body: 'Hi')
      described_class.new.perform(channel: 'sms', recipient: '+33612345678', payload: { 'body' => 'Hi' })
    end
  end

  describe 'unknown channel' do
    it 'logs a warning and returns' do
      expect(Rails.logger).to receive(:warn).with(/unknown channel/)
      described_class.new.perform(channel: 'pigeon', recipient: 'x', payload: {})
    end
  end
end
