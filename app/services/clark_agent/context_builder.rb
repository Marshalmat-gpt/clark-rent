# Construit un snapshot du contexte utilisateur consommé par l'agent IA :
# rôle, propriétés, baux actifs, candidatures, tickets ouverts.
#
# Usage : ClarkAgent::ContextBuilder.new(user: current_user).call
module ClarkAgent
  class ContextBuilder
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call
      base = { user_id: user.id, role: user.role, name: "#{user.first_name} #{user.last_name}" }
      user.role == 'landlord' ? base.merge(landlord_context) : base.merge(tenant_context)
    end

    private

    def landlord_context
      properties = user.properties.includes(rooms: :leases)
      {
        properties_count: properties.size,
        rooms_count: properties.sum { |p| p.rooms.size },
        active_leases_count: properties.sum { |p| p.rooms.sum { |r| r.leases.where(status: 'active').size } },
        open_tickets_count: Ticket.joins(room: :property)
                            .where(properties: { user_id: user.id })
                                  .open_tickets.count
      }
    end

    def tenant_context
      {
        active_leases: user.leases.where(status: 'active').pluck(:id),
        applications_count: user.lease_applications.count,
        open_tickets_count: Ticket.where(reporter: user).open_tickets.count
      }
    end
  end
end
