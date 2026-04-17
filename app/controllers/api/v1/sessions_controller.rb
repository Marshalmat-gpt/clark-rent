module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user).attributes }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def destroy
        # JWT is stateless — client must discard the token
        render json: { message: 'Signed out successfully' }, status: :ok
      end
    end
  end
end
