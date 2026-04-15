module ClarkAgent
  class ToolDefinitions
    def self.all
      [
        {
          name: 'get_my_lease',
          description: 'Retourne les détails du bail actif du locataire connecté.',
          input_schema: { type: 'object', properties: {}, required: [] }
        },
        {
          name: 'get_payment_history',
          description: "Retourne l'historique des paiements et quittances du locataire.",
          input_schema: {
            type: 'object',
            properties: {
              limit: { type: 'integer', description: 'Nombre de mois (défaut: 12)' }
            },
            required: []
          }
        },
        {
          name: 'create_ticket',
          description: "Ouvre un ticket d'intervention ou de signalement pour le bien du locataire.",
          input_schema: {
            type: 'object',
            properties: {
              category:    { type: 'string', enum: %w[plomberie electricite chauffage serrurerie autre] },
              description: { type: 'string' },
              priority:    { type: 'string', enum: %w[normal urgent], default: 'normal' }
            },
            required: %w[category description]
          }
        },
        {
          name: 'get_ticket_status',
          description: "Retourne le statut des tickets d'intervention. Omit ticket_id pour tous les tickets ouverts.",
          input_schema: {
            type: 'object',
            properties: {
              ticket_id: { type: 'integer' }
            },
            required: []
          }
        },
        {
          name: 'get_document',
          description: 'Génère un lien de téléchargement sécurisé (S3 presigned URL) pour un document.',
          input_schema: {
            type: 'object',
            properties: {
              document_type: { type: 'string', enum: %w[lease receipt residence_certificate inventory] },
              month:         { type: 'string', description: 'Format YYYY-MM pour les quittances' }
            },
            required: %w[document_type]
          }
        },
        {
          name: 'list_properties',
          description: 'Retourne la liste des biens du propriétaire avec statut des baux.',
          input_schema: {
            type: 'object',
            properties: {
              status: { type: 'string', enum: %w[all open closed inprogress] }
            },
            required: []
          }
        },
        {
          name: 'get_property',
          description: "Retourne les détails complets d'un bien (bail, locataire, paiements récents).",
          input_schema: {
            type: 'object',
            properties: {
              property_id: { type: 'integer' }
            },
            required: %w[property_id]
          }
        },
        {
          name: 'list_applications',
          description: 'Retourne les candidatures pour un bail donné.',
          input_schema: {
            type: 'object',
            properties: {
              lease_id: { type: 'integer' },
              status:   { type: 'string', enum: %w[new inprogress approved rejected_by_owner rejected_by_staff] }
            },
            required: %w[lease_id]
          }
        },
        {
          name: 'calculate_irl_revision',
          description: "Calcule le nouveau loyer selon l'Indice de Référence des Loyers en vigueur.",
          input_schema: {
            type: 'object',
            properties: {
              lease_id: { type: 'integer' }
            },
            required: %w[lease_id]
          }
        },
        {
          name: 'generate_rent_receipt',
          description: 'Génère et envoie la quittance de loyer mensuelle au locataire.',
          input_schema: {
            type: 'object',
            properties: {
              lease_id: { type: 'integer' },
              month:    { type: 'string', description: 'Format YYYY-MM' }
            },
            required: %w[lease_id month]
          }
        }
      ]
    end
  end
end
