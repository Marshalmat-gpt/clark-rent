class RentReceiptGenerator
  def self.generate(lease:, month:)
    tenant   = lease.tenant
    property = lease.property
    owner    = property.owner

    Prawn::Document.new(page_size: 'A4', margin: [60, 60, 60, 60]) do |pdf|
      # En-tête
      pdf.font_size(18) { pdf.text 'QUITTANCE DE LOYER', style: :bold, align: :center }
      pdf.move_down 4
      pdf.text "Mois de #{month.strftime('%B %Y').capitalize}", align: :center, size: 13
      pdf.move_down 20

      # Séparateur
      pdf.stroke_horizontal_rule
      pdf.move_down 16

      # Propriétaire
      pdf.text 'Propriétaire', style: :bold, size: 11
      pdf.text owner.full_name
      pdf.text owner.email
      pdf.move_down 12

      # Locataire
      pdf.text 'Locataire', style: :bold, size: 11
      pdf.text tenant.full_name
      pdf.text property.formatted_address
      pdf.move_down 12

      # Bien loué
      pdf.text 'Bien loué', style: :bold, size: 11
      pdf.text property.formatted_address
      pdf.text "Surface : #{property.area} m²" if property.area
      pdf.move_down 16

      # Montants
      pdf.stroke_horizontal_rule
      pdf.move_down 12

      rows = [
        ['Loyer hors charges', "#{lease.amount} €"],
        ['Charges', "#{lease.expense_amount || 0} €"],
        ['Total', "#{(lease.amount + (lease.expense_amount || 0)).round(2)} €"]
      ]

      pdf.table(rows, width: pdf.bounds.width, cell_style: { size: 11, padding: [6, 10] }) do
        row(0).borders = [:top, :bottom]
        row(-1).font_style = :bold
        row(-1).borders = [:top, :bottom]
        column(1).align = :right
      end

      pdf.move_down 20

      # Déclaration
      pdf.text(
        "Je soussigné(e) #{owner.full_name}, bailleur du logement désigné ci-dessus, " \
        "déclare avoir reçu de #{tenant.full_name} la somme de " \
        "#{(lease.amount + (lease.expense_amount || 0)).round(2)} euros " \
        "au titre du loyer et des charges du mois de #{month.strftime('%B %Y')}.",
        size: 11
      )

      pdf.move_down 24

      # Signature
      pdf.text "Fait le #{Date.today.strftime('%d/%m/%Y')}", size: 10
      pdf.text owner.full_name, size: 10, style: :italic
      pdf.move_down 4
      pdf.text 'Document généré par Clark Rent', size: 8, color: '888888'
    end.render
  end
end
