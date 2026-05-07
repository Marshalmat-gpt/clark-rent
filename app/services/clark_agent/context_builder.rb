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
      properties = user.properties.includes(:leases)
      {
        properties_count: properties.size,
        active_leases_count: properties.sum { |p| p.leases.count { |l| l.status == 'active' } },
        open_tickets_count: Ticket.for_owner(user).open.count
      }
    end

    def tenant_context
      {
        active_leases: user.leases.where(status: 'active').pluck(:id),
        applications_count: user.lease_applications.count,
        open_tickets_count: Ticket.where(tenant: user).open.count
      }
    end
  end
end
