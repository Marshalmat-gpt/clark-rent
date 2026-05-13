module ClarkAgent
  class ToolRegistry
    TOOL_SPECS = [
      # ── Tenant tools ────────────────────────────────────────────────────────
      {
        name: 'get_my_lease',
        description: "Renvoie les détails du bail actif du locataire (loyer, charges, adresse, dates, statut).",
        input_schema: { type: 'object', properties: {}, required: [] }
      },
      {
        name: 'get_payment_history',
        description: "Renvoie l'historique des paiements de loyer du locataire.",
        input_schema: {
          type: 'object',
          properties: {
            limit: { type: 'integer', description: 'Nombre max de paiements (défaut 10, max 100)' }
          },
          required: []
        }
      },
      {
        name: 'create_ticket',
        description: 'Crée un ticket de maintenance pour le logement du locataire et notifie le propriétaire.',
        input_schema: {
          type: 'object',
          properties: {
            category: { type: 'string', description: 'Catégorie du problème' },
            description: { type: 'string', description: 'Description détaillée du problème' },
            priority: { type: 'string', enum: %w[normal urgent], description: 'Urgence (défaut: normal)' }
          },
          required: %w[category description]
        }
      },
      {
        name: 'get_ticket_status',
        description: "Retourne les tickets de maintenance du locataire (ouverts par défaut).",
        input_schema: {
          type: 'object',
          properties: {
            ticket_id: { type: 'integer', description: 'ID du ticket (optionnel, sinon liste tous les ouverts)' }
          },
          required: []
        }
      },
      {
        name: 'get_document',
        description: "Renvoie une URL signée (1h) pour télécharger un document : bail, quittance, attestation de résidence, ou état des lieux.",
        input_schema: {
          type: 'object',
          properties: {
            document_type: {
              type: 'string',
              enum: %w[lease receipt residence_certificate inventory],
              description: 'Type de document'
            },
            month: { type: 'string', description: 'Mois YYYY-MM (requis pour les quittances)' }
          },
          required: %w[document_type]
        }
      },
      # ── Owner tools ──────────────────────────────────────────────────────────
      {
        name: 'list_properties',
        description: "Liste les propriétés du propriétaire avec alertes (bail expirant, tickets ouverts).",
        input_schema: {
          type: 'object',
          properties: {
            status: { type: 'string', enum: %w[active expired all], description: 'Filtre par statut de bail (optionnel)' }
          },
          required: []
        }
      },
      {
        name: 'get_property',
        description: "Détail complet d'une propriété : bail actif, coordonnées locataire, 5 tickets récents.",
        input_schema: {
          type: 'object',
          properties: {
            property_id: { type: 'integer', description: 'ID de la propriété' }
          },
          required: %w[property_id]
        }
      },
      {
        name: 'list_applications',
        description: "Liste les candidatures de location pour un bail.",
        input_schema: {
          type: 'object',
          properties: {
            lease_id: { type: 'integer', description: 'ID du bail' },
            status: { type: 'string', enum: %w[pending approved rejected], description: 'Filtre par statut (optionnel)' }
          },
          required: %w[lease_id]
        }
      },
      {
        name: 'calculate_irl_revision',
        description: "Calcule la révision de loyer via l'indice IRL pour un bail donné.",
        input_schema: {
          type: 'object',
          properties: {
            lease_id: { type: 'integer', description: 'ID du bail' }
          },
          required: %w[lease_id]
        }
      },
      {
        name: 'generate_rent_receipt',
        description: "Génère la quittance de loyer d'un mois et l'envoie au locataire par email.",
        input_schema: {
          type: 'object',
          properties: {
            lease_id: { type: 'integer', description: 'ID du bail' },
            month: { type: 'string', description: 'Mois au format YYYY-MM' }
          },
          required: %w[lease_id month]
        }
      }
    ].freeze

    def self.tool_specs
      TOOL_SPECS
    end
  end
end
