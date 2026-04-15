module ClarkAgent
  class ToolExecutor
    def self.execute(name:, input:, user:, role:)
      case name
      when 'get_my_lease'           then get_my_lease(user)
      when 'get_payment_history'    then get_payment_history(user, input)
      when 'create_ticket'          then create_ticket(user, input)
      when 'get_ticket_status'      then get_ticket_status(user, input)
      when 'get_document'           then get_document(user, input)
      when 'list_properties'        then list_properties(user, input)
      when 'get_property'           then get_property(user, input)
      when 'list_applications'      then list_applications(user, input)
      when 'calculate_irl_revision' then calculate_irl_revision(user, input)
      when 'generate_rent_receipt'  then generate_rent_receipt(user, input)
      else
        { content: { error: "Outil inconnu : #{name}" } }
      end
    rescue => e
      Rails.logger.error "[ToolExecutor] #{name} failed: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
      { content: { error: e.message } }
    end

    # ── Outils Locataire ────────────────────────────────────────────────────

    def self.get_my_lease(user)
      lease = user.active_lease
      return { content: { error: 'Aucun bail actif trouvé.' } } unless lease

      {
        content: {
          id:             lease.id,
          status:         lease.status,
          amount:         lease.amount,
          expense_amount: lease.expense_amount,
          start_date:     lease.start_date&.strftime('%d/%m/%Y'),
          end_date:       lease.end_date&.strftime('%d/%m/%Y'),
          days_to_expiry: lease.end_date ? (lease.end_date - Date.today).to_i : nil,
          property: {
            address: lease.property.formatted_address,
            type:    lease.property.property_type,
            surface: lease.property.area,
            city:    lease.property.city,
            energy:  lease.property.energy
          }
        }
      }
    end

    def self.get_payment_history(user, input)
      lease = user.active_lease
      return { content: { error: 'Aucun bail actif.' } } unless lease

      limit    = (input['limit'] || 12).to_i
      payments = lease.rent_payments.order(paid_at: :desc).limit(limit)

      {
        content: {
          payments: payments.map { |p|
            {
              month:   p.paid_at&.strftime('%B %Y'),
              amount:  p.amount,
              status:  p.status,
              paid_at: p.paid_at&.strftime('%d/%m/%Y')
            }
          },
          total_paid: payments.sum(&:amount),
          on_time_count: payments.count { |p| p.status == 'paid' }
        }
      }
    end

    def self.create_ticket(user, input)
      lease = user.active_lease
      return { content: { error: 'Aucun bail actif.' } } unless lease

      ticket = Ticket.create!(
        property:    lease.property,
        tenant:      user,
        category:    input['category'],
        description: input['description'],
        priority:    input['priority'] || 'normal',
        status:      'open'
      )

      # Notifier le propriétaire de façon asynchrone
      OwnerNotificationJob.perform_later(
        owner_id:  lease.property.owner_id,
        ticket_id: ticket.id,
        channel:   :email
      )

      {
        content: {
          ticket_id:          ticket.id,
          status:             ticket.status,
          priority:           ticket.priority,
          estimated_response: ticket.priority == 'urgent' ? '24h' : '72h',
          message:            "Ticket ##{ticket.id} créé. Votre propriétaire a été notifié."
        }
      }
    end

    def self.get_ticket_status(user, input)
      scope = Ticket.where(tenant: user).order(created_at: :desc)
      scope = scope.where(id: input['ticket_id']) if input['ticket_id'].present?
      scope = scope.open unless input['ticket_id'].present?

      {
        content: {
          tickets: scope.map { |t|
            {
              id:          t.id,
              category:    t.category,
              description: t.description,
              status:      t.status,
              priority:    t.priority,
              created_at:  t.created_at.strftime('%d/%m/%Y'),
              assigned_to: t.assigned_to&.full_name,
              resolved_at: t.resolved_at&.strftime('%d/%m/%Y')
            }
          }
        }
      }
    end

    def self.get_document(user, input)
      lease = user.active_lease
      return { content: { error: 'Aucun bail actif.' } } unless lease

      url = case input['document_type']
            when 'lease'
              presigned_url(lease.document)
            when 'receipt'
              month   = Date.parse("#{input['month']}-01")
              payment = lease.rent_payments.find_by('paid_at >= ? AND paid_at <= ?', month.beginning_of_month, month.end_of_month)
              return { content: { error: "Quittance introuvable pour #{input['month']}." } } unless payment
              presigned_url(payment.receipt)
            when 'residence_certificate'
              ResidenceCertificateGenerator.generate_url(lease: lease)
            when 'inventory'
              presigned_url(lease.inventory_document)
            else
              return { content: { error: "Type de document inconnu : #{input['document_type']}." } }
            end

      return { content: { error: 'Document non trouvé ou non encore généré.' } } unless url

      {
        content: {
          url:        url,
          expires_in: '1 heure',
          type:       input['document_type']
        },
        # action renvoyée au frontend pour afficher un bouton de téléchargement
        action: {
          type:  'download_url',
          url:   url,
          label: document_label(input['document_type'], input['month'])
        }
      }
    end

    # ── Outils Propriétaire ──────────────────────────────────────────────────

    def self.list_properties(user, input)
      props = user.properties.includes(:leases, :tickets)
      if input['status'].present? && input['status'] != 'all'
        props = props.joins(:leases).where(leases: { status: input['status'] })
      end

      {
        content: {
          count:      props.count,
          properties: props.map { |p|
            lease      = p.leases.order(created_at: :desc).first
            open_tkts  = p.tickets.open.count

            alerts = []
            alerts << "⚠️ Bail expire dans #{(lease.end_date - Date.today).to_i}j" if lease&.end_date && (lease.end_date - Date.today).to_i <= 60
            alerts << "🚨 #{open_tkts} ticket(s) ouvert(s)" if open_tkts > 0

            {
              id:           p.id,
              address:      p.formatted_address,
              city:         p.city,
              surface:      p.area,
              lease_status: lease&.status || 'no_lease',
              rent:         lease&.amount,
              tenant:       lease&.tenant&.full_name,
              open_tickets: open_tkts,
              alerts:       alerts
            }
          }
        }
      }
    end

    def self.get_property(user, input)
      property = user.properties.find(input['property_id'])
      lease    = property.leases.where(status: 'open').last

      {
        content: {
          property: {
            id:       property.id,
            address:  property.formatted_address,
            surface:  property.area,
            type:     property.property_type,
            energy:   property.energy,
            dpe_date: property.date_dpe&.strftime('%d/%m/%Y'),
            floors:   property.floor
          },
          lease: lease ? {
            id:             lease.id,
            status:         lease.status,
            amount:         lease.amount,
            expense_amount: lease.expense_amount,
            tenant:         lease.tenant&.full_name,
            tenant_phone:   lease.tenant&.phone,
            start_date:     lease.start_date&.strftime('%d/%m/%Y'),
            end_date:       lease.end_date&.strftime('%d/%m/%Y'),
            days_to_expiry: lease.end_date ? (lease.end_date - Date.today).to_i : nil
          } : nil,
          recent_tickets: property.tickets.order(created_at: :desc).limit(5).map { |t|
            {
              id:       t.id,
              category: t.category,
              status:   t.status,
              priority: t.priority,
              date:     t.created_at.strftime('%d/%m/%Y')
            }
          }
        }
      }
    rescue ActiveRecord::RecordNotFound
      { content: { error: "Bien ##{input['property_id']} introuvable ou non autorisé." } }
    end

    def self.list_applications(user, input)
      lease = user.properties
                  .flat_map(&:leases)
                  .find { |l| l.id == input['lease_id'].to_i }

      return { content: { error: 'Bail introuvable ou non autorisé.' } } unless lease

      apps = lease.lease_applications.includes(:applicant)
      apps = apps.where(status: input['status']) if input['status'].present?

      {
        content: {
          lease_id:     lease.id,
          applications: apps.map { |a|
            {
              id:          a.id,
              status:      a.status,
              applicant:   a.applicant&.full_name,
              email:       a.applicant&.email,
              description: a.description,
              submitted_at: a.created_at.strftime('%d/%m/%Y')
            }
          }
        }
      }
    end

    def self.calculate_irl_revision(user, input)
      lease = user.properties
                  .flat_map(&:leases)
                  .find { |l| l.id == input['lease_id'].to_i }

      return { content: { error: 'Bail introuvable.' } } unless lease

      # IRL Q1 2025 (source INSEE) — à mettre à jour trimestriellement
      irl_current   = 143.46
      irl_reference = lease.irl_reference || 140.59
      new_rent      = (lease.amount * irl_current / irl_reference).round(2)
      delta         = (new_rent - lease.amount).round(2)
      revision_date = lease.start_date&.then { |d|
        # Prochaine date anniversaire du bail
        this_year = d.change(year: Date.today.year)
        this_year < Date.today ? this_year.next_year : this_year
      }

      {
        content: {
          current_rent:   lease.amount,
          new_rent:       new_rent,
          delta:          delta,
          delta_percent:  ((delta / lease.amount) * 100).round(2),
          irl_applied:    irl_current,
          irl_reference:  irl_reference,
          revision_date:  revision_date&.strftime('%d/%m/%Y'),
          annual_gain:    (delta * 12).round(2),
          tenant:         lease.tenant&.full_name
        }
      }
    end

    def self.generate_rent_receipt(user, input)
      lease = user.properties
                  .flat_map(&:leases)
                  .find { |l| l.id == input['lease_id'].to_i }

      return { content: { error: 'Bail introuvable.' } } unless lease

      month  = Date.parse("#{input['month']}-01")
      pdf    = RentReceiptGenerator.generate(lease: lease, month: month)
      key    = "receipts/#{lease.id}/#{input['month']}.pdf"
      url    = upload_to_s3(pdf, key)

      # Envoyer par email au locataire
      TenantMailer.rent_receipt(
        lease: lease,
        month: month,
        url:   url
      ).deliver_later

      {
        content: {
          url:     url,
          month:   month.strftime('%B %Y'),
          tenant:  lease.tenant&.full_name,
          amount:  lease.amount + (lease.expense_amount || 0),
          message: "Quittance générée et envoyée à #{lease.tenant&.full_name} par email."
        },
        action: {
          type:  'download_url',
          url:   url,
          label: "Quittance #{month.strftime('%B %Y')}"
        }
      }
    end

    # ── Helpers privés ───────────────────────────────────────────────────────

    def self.presigned_url(attachment)
      return nil unless attachment&.attached?
      attachment.blob.service_url(expires_in: 1.hour)
    end

    def self.upload_to_s3(content, key)
      s3  = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
      obj = s3.bucket(ENV['AWS_BUCKET']).object(key)
      obj.put(body: content, content_type: 'application/pdf')
      obj.presigned_url(:get, expires_in: 3600)
    end

    def self.document_label(type, month = nil)
      case type
      when 'lease'                  then 'Télécharger le bail'
      when 'receipt'                then "Quittance #{month}"
      when 'residence_certificate'  then 'Attestation de résidence'
      when 'inventory'              then "État des lieux"
      else 'Télécharger le document'
      end
    end
  end
end
