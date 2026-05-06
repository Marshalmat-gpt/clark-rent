module Api
  module V1
    class LeasesController < BaseController
      before_action :set_lease, only: %i[show update destroy terminate]

      def index
        leases = current_user_leases.includes(:room, :tenant).order(created_at: :desc)
        render json: leases, each_serializer: LeaseSerializer
      end

      def show = render json: @lease, serializer: LeaseSerializer

      def create
        room = Room.find(lease_params[:room_id])
        authorize_landlord_for!(room)
        lease = Lease.new(lease_params.except(:room_id).merge(room: room))

        if lease.save
          render json: lease, serializer: LeaseSerializer, status: :created
        else
          render json: { errors: lease.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize_landlord!
        if @lease.update(lease_update_params)
          render json: @lease, serializer: LeaseSerializer
        else
          render json: { errors: @lease.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize_landlord!
        @lease.destroy
        render json: { message: 'Lease deleted' }, status: :ok
      end

      def terminate
        authorize_landlord!
        if @lease.update(status: 'terminated', end_date: Date.current)
          render json: @lease, serializer: LeaseSerializer
        else
          render json: { errors: @lease.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_lease
        @lease = current_user_leases.find(params[:id])
      end

      # Landlords see leases on their rooms; tenants see their own.
      def current_user_leases
        if current_user.role == 'landlord'
          Lease.joins(room: :property).where(properties: { user_id: current_user.id })
        else
          current_user.leases
        end
      end

      def authorize_landlord!
        authorize_landlord_for!(@lease.room)
      end

      def authorize_landlord_for!(room)
        return if current_user.role == 'landlord' && room.property.user_id == current_user.id

        render json: { error: 'Forbidden' }, status: :forbidden and return
      end

      def lease_params
        params.require(:lease).permit(
          :tenant_id, :room_id, :start_date, :end_date,
          :monthly_rent, :monthly_charges, :deposit, :status, :signed_at
        )
      end

      def lease_update_params
        params.require(:lease).permit(
          :end_date, :monthly_rent, :monthly_charges, :deposit, :status, :signed_at
        )
      end
    end
  end
end
