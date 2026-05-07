require 'rails_helper'

RSpec.describe ReceiptMailer, type: :mailer do
  let(:landlord) { create(:user, role: 'landlord') }
  let(:tenant)   { create(:user, :tenant, email: 'tenant@example.com') }
  let(:property) { create(:property, user: landlord) }
  let(:room)     { create(:room, property: property) }
  let(:lease)    { create(:lease, room: room, tenant: tenant) }
  let(:pdf_io)   { StringIO.new('%PDF-1.4 fake pdf bytes') }

  it 'attaches the PDF to the email' do
    mail = described_class.delivered(
      lease_id: lease.id,
      period: Date.new(2026, 4, 1),
      pdf_io: pdf_io
    )

    expect(mail.to).to eq(['tenant@example.com'])
    expect(mail.attachments.size).to eq(1)
    expect(mail.attachments.first.filename).to eq('quittance-2026-04.pdf')
    expect(mail.attachments.first.content_type).to start_with('application/pdf')
  end
end
