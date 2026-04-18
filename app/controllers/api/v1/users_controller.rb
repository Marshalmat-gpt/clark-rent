module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: %i[create]
      before_action :set_user, only: %i[show update destroy]

      def index = render json: User.order(:created_at), each_serializer: UserSerializer

      def show = render json: @user, serializer: UserSerializer

      def create
        user = User.new(user_params)
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user).attributes }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        authorize_self!
        return unless performed?
        if @user.update(user_params)
          render json: @user, serializer: UserSerializer
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        authorize_self!
        return unless performed?
        @user.destroy
        render json: { message: 'Account deleted' }, status: :ok
      end

      private

      def set_user = @user = User.find(params[:id])

      def authorize_self!
        return if @user == current_user

        render json: { error: 'Forbidden' }, status: :forbidden
      end

      def user_params = params.permit(:email, :password, :first_name, :last_name, :role)
    end
  end
end
