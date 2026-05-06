module Api
  module V1
    class LeaseApplicationsController < BaseController
      before_action :set_application, only: %i[show update destroy validate]

      def index
        apps = scoped_applications.includes(:room, :tenant).order(created_at: :desc)
        render json: apps, each_serializer: LeaseApplicationSerializer
      end

      def show = render json: @application, serializer: LeaseApplicationSerializer

      def create
        application = current_user.lease_applications.build(create_params)
        if application.save
          render json: application, serializer: LeaseApplicationSerializer, status: :created
        else
          render json: { errors: application.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return forbidden unless owner?

        if @application.update(update_params)
          render json: @application, serializer: LeaseApplicationSerializer
        else
          render json: { errors: @application.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return forbidden unless owner?

        @application.destroy
        render json: { message: 'Application deleted' }, status: :ok
      end

      # PATCH /api/v1/lease_applications/:id/validate
      # Body: { decision: "approved" | "rejected" }
      def validate
        return forbidden unless landlord_for_room?
        return render_invalid_decision unless %w[approved rejected].include?(params[:decision].to_s)

        method = params[:decision] == 'approved' ? :approve! : :reject!
        @application.public_send(method, by: current_user)
        render json: @application, serializer: LeaseApplicationSerializer
      end

      private

      def render_invalid_decision
        render json: { error: 'decision must be approved or rejected' }, status: :unprocessable_entity
      end

      def set_application
        @application = scoped_applications.find(params[:id])
      end

      def scoped_applications
        if current_user.role == 'landlord'
          LeaseApplication.joins(room: :property).where(properties: { user_id: current_user.id })
        else
          current_user.lease_applications
        end
      end

      def owner?
        @application.tenant_id == current_user.id
      end

      def landlord_for_room?
        current_user.role == 'landlord' && @application.room.property.user_id == current_user.id
      end

      def forbidden
        render json: { error: 'Forbidden' }, status: :forbidden
      end

      def create_params
        params.require(:lease_application).permit(:room_id, :message)
      end

      def update_params
        params.require(:lease_application).permit(:message)
      end
    end
  end
end
