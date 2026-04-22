require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Fix TSort::Cyclic caused by active_model_serializers 0.10.x on Rails 7.2+.
# The 'set_configs' initializer declares `after: 'action_controller.set_configs'`
# which creates a circular dependency in Rails 7.2's initializer graph.
# Removing it from the railtie's InitializerCollection before initialize! is
# called prevents the cycle. AMS logger is wired separately via
# config/initializers/ams_logger.rb.
if defined?(ActiveModelSerializers::Railtie)
  ActiveModelSerializers::Railtie.initializers.delete_if do |i|
    i.name.to_s == 'active_model_serializers.set_configs'
  end
end

module ClarkRent
  class Application < Rails::Application
    config.load_defaults 7.2
    config.api_only = true
    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
  end
end
