# Restores ActiveModelSerializers logger wiring without TSort::Cyclic.
# Replaces the ordering removed from active_model_serializers.set_configs
# in config/application.rb. on_load defers until ActionController is ready.
ActiveSupport.on_load(:action_controller) do
  ActiveModelSerializers.logger =
    Rails.configuration.action_controller.logger || Rails.logger
end
