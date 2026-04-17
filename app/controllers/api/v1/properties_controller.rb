module Api
  module V1
    class PropertiesController < BaseController
      before_action :set_property, only: [:show, :update, :destroy, :documents]

      def index = render json: current_user.properties.order(:created_at), each_serializer: PropertySerializer

      def show = render json: @property, serializer: PropertySerializer

      def create
        property = current_user.properties.build(property_params)
        if property.save
          render json: property, serializer: PropertySerializer, status: :created
        else
          render json: { errors: property.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @property.update(property_params)
          render json: @property, serializer: PropertySerializer
        else
          render json: { errors: @property.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @property.destroy
        render json: { message: 'Property deleted' }, status: :ok
      end

      def documents = render json: { documents: [] }

      private

      def set_property = @property = current_user.properties.find(params[:id])

      def property_params = params.require(:property).permit(:name, :address)
    end
  end
end
