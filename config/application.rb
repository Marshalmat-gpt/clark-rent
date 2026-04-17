require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Fix TSort::Cyclic caused by active_model_serializers 0.10.x on Rails 7.2+
# The `active_model_serializers.set_configs` initializer declares
# `after: 'action_controller.set_configs'` which creates a cyclic dependency
# in Rails 7.2's global initializer graph when combined with auto-chaining.
# Fix: remove the :after ordering constraint from that single initializer only.
# Logger wiring is restored by config/initializers/ams_logger.rb.
if defined?(ActiveModelSerializers::Railtie)
  ams_init = ActiveModelSerializers::Railtie.initializers
                                            .find { |i| i.name == 'active_model_serializers.set_configs' }
  ams_init&.instance_variable_get(:@options)&.delete(:after)
end

module ClarkRent
  class Application < Rails::Application
    config.load_defaults 7.2
    config.api_only = true
    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
  end
end
