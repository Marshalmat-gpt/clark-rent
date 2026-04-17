require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Workaround: active_model_serializers 0.10.x TSort::Cyclic with Rails 7.2+
# AMS registers initializers with `after: 'action_controller.logger'` (string
# reference) which creates a cyclic dependency in Rails 7.2's initializer graph.
# Safe to patch: all AMS hooks use ActiveSupport.on_load (deferred execution),
# so strict ordering against a named initializer is unnecessary.
if defined?(ActiveModelSerializers::Railtie)
  ActiveModelSerializers::Railtie.initializers.each do |init|
    next unless init.name.to_s.start_with?('active_model_serializers')

    opts = init.instance_variable_get(:@options)
    opts.delete(:after) if opts.is_a?(Hash) && opts[:after].is_a?(String)
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
