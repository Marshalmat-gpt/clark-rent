# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
# Registre des outils exposés à Claude. Chaque entrée :
#   :name        — identifiant côté API (snake_case)
#   :description — explique l'outil dans le system prompt
#   :input_schema — JSON Schema des paramètres d'entrée
#   :handler     — lambda(user:, **input) -> Hash sérialisable JSON
#
# Le ToolRegistry n'a pas de stockage propre — il délègue aux services
# domaine déjà existants (ContextBuilder, IrlCalculator, modèles AR).
module ClarkAgent
  class ToolRegistry
    Tool = Struct.new(:name, :description, :input_schema, :handler, keyword_init: true)

    def self.tools
      @tools ||= [
        Tool.new(
          name: 'get_user_context',
          description: "Renvoie le contexte courant de l'utilisateur (rôle, propriétés, baux actifs, tickets ouverts).",
          input_schema: { type: 'object', properties: {}, required: [] },
          handler: ->(user:, **) { ContextBuilder.new(user: user).call }
        ),
        Tool.new(
          name: 'list_properties',
          description: 'Liste les propriétés du bailleur courant avec leur revenu mensuel actif.',
          input_schema: { type: 'object', properties: {}, required: [] },
          handler: lambda do |user:, **|
            return { error: 'Landlord only' } unless user.role == 'landlord'

            user.properties.includes(rooms: :leases).map do |p|
              {
                id: p.id,
                name: p.name,
                address: p.address,
                rooms_count: p.rooms.size,
                monthly_revenue: p.rooms.sum { |r| r.leases.where(status: 'active').sum(:monthly_rent) }
              }
            end
          end
        ),
        Tool.new(
          name: 'calculate_irl_revision',
          description: "Calcule la révision annuelle d'un loyer via la formule IRL.",
          input_schema: {
            type: 'object',
            properties: {
              lease_id: { type: 'integer', description: 'ID du bail concerné' },
              base_irl: { type: 'number',  description: 'Indice IRL de référence' },
              current_irl: { type: 'number', description: 'Indice IRL actuel' }
            },
            required: %w[lease_id base_irl current_irl]
          },
          handler: lambda do |user:, **input|
            lease = scoped_leases(user).find_by(id: input[:lease_id])
            return { error: 'Lease not found' } unless lease

            IrlCalculator.new(
              reference_rent: lease.monthly_rent,
              base_irl: input[:base_irl],
              current_irl: input[:current_irl]
            ).call
          end
        ),
        Tool.new(
          name: 'list_tickets',
          description: "Liste les tickets ouverts visibles par l'utilisateur courant.",
          input_schema: {
            type: 'object',
            properties: {
              status: { type: 'string', enum: Ticket::STATUSES, description: 'Filtre optionnel par statut' }
            },
            required: []
          },
          handler: lambda do |user:, **input|
            scope = scoped_tickets(user)
            scope = scope.where(status: input[:status]) if input[:status].present?
            scope.order(created_at: :desc).limit(20).as_json(
              only: %i[id category status priority property_id tenant_id created_at resolved_at]
            )
          end
        ),
        Tool.new(
          name: 'create_ticket',
          description: 'Crée un nouveau ticket de maintenance pour la propriété du locataire.',
          input_schema: {
            type: 'object',
            properties: {
              category: { type: 'string', enum: Ticket::CATEGORIES },
              description: { type: 'string' },
              priority: { type: 'string', enum: Ticket::PRIORITIES }
            },
            required: %w[category description]
          },
          handler: lambda do |user:, **input|
            property = user.leases.where(status: 'active').joins(:room).first&.room&.property
            return { error: 'No active lease found' } unless property

            ticket = Ticket.new(
              property: property,
              tenant: user,
              category: input[:category],
              description: input[:description],
              priority: input[:priority] || 'normal'
            )
            if ticket.save
              { id: ticket.id, status: ticket.status, priority: ticket.priority, category: ticket.category }
            else
              { error: ticket.errors.full_messages.join(', ') }
            end
          end
        )
      ]
    end

    def self.find(name)
      tools.find { |t| t.name == name.to_s }
    end

    def self.tool_specs
      tools.map { |t| { name: t.name, description: t.description, input_schema: t.input_schema } }
    end

    def self.scoped_leases(user)
      if user.role == 'landlord'
        Lease.joins(room: :property).where(properties: { user_id: user.id })
      else
        user.leases
      end
    end

    def self.scoped_tickets(user)
      if user.role == 'landlord'
        Ticket.for_owner(user)
      else
        Ticket.where(tenant: user)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
