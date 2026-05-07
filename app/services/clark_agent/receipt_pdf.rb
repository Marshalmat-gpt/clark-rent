require 'prawn'
require 'prawn/table'

# Génère une quittance de loyer PDF en mémoire (StringIO) à partir
# d'un Lease + période ciblée.
#
# Usage :
#   io = ClarkAgent::ReceiptPdf.new(lease: lease, period: Date.new(2026, 4, 1)).render
#   S3Service.upload(file: io, key: "receipts/#{lease.id}/#{period}.pdf",
#                    content_type: 'application/pdf')
module ClarkAgent
  class ReceiptPdf
    attr_reader :lease, :period

    def initialize(lease:, period: Date.current)
      @lease  = lease
      @period = period.is_a?(Date) ? period : Date.parse(period.to_s)
    end

    def render
      io = StringIO.new
      Prawn::Document.new.tap do |pdf|
        write_header(pdf)
        write_parties(pdf)
        write_breakdown(pdf)
        write_footer(pdf)
      end.render(io)
      io.rewind
      io
    end

    private

    def total
      lease.monthly_rent + lease.monthly_charges
    end

    def write_header(pdf)
      pdf.text 'QUITTANCE DE LOYER', size: 20, style: :bold, align: :center
      pdf.move_down 10
      pdf.text "Période : #{period.strftime('%B %Y')}", align: :center
      pdf.move_down 20
    end

    def write_parties(pdf)
      tenant   = lease.tenant
      landlord = lease.room.property.user
      pdf.text "Bailleur : #{landlord.first_name} #{landlord.last_name}"
      pdf.text "Locataire : #{tenant.first_name} #{tenant.last_name}"
      pdf.text "Logement : #{lease.room.property.address} — #{lease.room.name}"
      pdf.move_down 20
    end

    def write_breakdown(pdf)
      rows = [
        ['Loyer hors charges', format('%.2f €', lease.monthly_rent)],
        ['Provision charges',  format('%.2f €', lease.monthly_charges)],
        ['Total',              format('%.2f €', total)]
      ]
      pdf.table(rows, header: false, column_widths: [300, 100])
      pdf.move_down 20
    end

    def write_footer(pdf)
      pdf.text "Quittance émise le #{Date.current.strftime('%d/%m/%Y')}.", size: 10
      pdf.text 'Le présent reçu vaut quittance des sommes mentionnées ci-dessus.', size: 10
    end
  end
end
