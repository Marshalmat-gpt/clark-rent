module Api
  module V1
    class RoomsController < BaseController
      before_action :set_room, only: %i[update destroy]

      def index
        rooms = if params[:property_id]
                   current_user.properties.find(params[:property_id]).rooms
                 else
                   Room.joins(:property).where(properties: { user_id: current_user.id })
                 end
        render json: rooms.order(:created_at), each_serializer: RoomSerializer
      end

      def create
        if room_params[:property_id].blank? # rubocop:disable Style/GuardClause
          return render json: { errors: ["Property can't be blank"] }, status: :unprocessable_content
        end

        property = current_user.properties.find(room_params[:property_id])
        room = property.rooms.build(room_params.except('property_id'))
        if room.save
          render json: room, serializer: RoomSerializer, status: :created
        else
          render json: { errors: room.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @room.update(room_params.except('property_id'))
          render json: @room, serializer: RoomSerializer
        else
          render json: { errors: @room.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @room.destroy
        render json: { message: 'Room deleted' }, status: :ok
      end

      private

      def set_room
        @room = Room.joins(:property).where(properties: { user_id: current_user.id }).find(params[:id])
      end

      def room_params = params.require(:room).permit(:name, :surface_area, :rent, :charges, :property_id)
    end
  end
end
