module Api
  module V1
    module Agent
      class ContextController < BaseController
        def show
          render json: ClarkAgent::ContextBuilder.new(user: current_user).call
        end
      end
    end
  end
end
