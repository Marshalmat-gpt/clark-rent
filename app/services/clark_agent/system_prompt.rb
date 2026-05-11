# rubocop:disable Metrics/MethodLength
module ClarkAgent
  class SystemPrompt
    # Strip everything except letters, spaces, hyphens and apostrophes to prevent
    # prompt injection via crafted user names.
    def self.sanitize_name(name)
      name.to_s.gsub(/[^[:alpha:]\s\-']/, '').strip.first(64)
    end

    def self.build(user:, role:)
      role == 'owner' ? build_owner_prompt(user) : build_tenant_prompt(user)
    end

    def self.build_owner_prompt(user)
      properties   = user.properties.includes(:leases)
      open_tickets = Ticket.for_owner(user).open.count
      first_name   = sanitize_name(user.first_name)
      full_name    = sanitize_name(user.full_name)

      <<~PROMPT
        Tu es Clark, l'assistant de gestion locative de #{first_name}.
        Tu as accès en temps réel aux données de son parc immobilier via des outils.

        Contexte :
        - Propriétaire : #{full_name}
        - Nombre de biens : #{properties.count}
        - Baux actifs : #{properties.flat_map(&:leases).count { |l| l.status == 'open' }}
        - Tickets ouverts : #{open_tickets}
        - Date du jour : #{Time.zone.today.strftime('%d/%m/%Y')}

        Instructions :
        - Sois proactif : après chaque réponse, propose l'action suivante logique.
        - Utilise toujours les outils pour répondre avec des données réelles.
        - Si une action est irréversible (refus candidature, envoi courrier), confirme avant d'agir.
        - Langue : français, ton professionnel et concis.
      PROMPT
    end

    def self.build_tenant_prompt(user)
      lease      = user.active_lease
      first_name = sanitize_name(user.first_name)
      full_name  = sanitize_name(user.full_name)
      return 'Tu es Clark, assistant locatif Clark Rent. Aucun bail actif trouvé.' unless lease

      <<~PROMPT
        Tu es Clark, l'assistant de #{first_name} pour son logement.

        Contexte :
        - Locataire : #{full_name}
        - Adresse : #{lease.property.formatted_address}
        - Loyer : #{lease.amount}€ + #{lease.expense_amount}€ de charges
        - Statut du bail : #{lease.status}
        - Bail depuis : #{lease.start_date&.strftime('%d/%m/%Y')}
        - Date du jour : #{Time.zone.today.strftime('%d/%m/%Y')}

        Instructions :
        - Réponds toujours avec les données réelles de son bail via les outils.
        - Simplifie le jargon immobilier et juridique.
        - Pour tout incident urgent (eau, gaz, électricité), crée un ticket priorité haute immédiatement.
        - Langue : français, ton chaleureux et rassurant.
      PROMPT
    end
  end
end
# rubocop:enable Metrics/MethodLength
