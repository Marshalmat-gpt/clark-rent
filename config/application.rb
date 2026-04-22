require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Fix TSort::Cyclic caused by active_model_serializers 0.10.x on Rails 7.2+
# @options is frozen in Rails 7.2, so we cannot use Hash#delete in place.
# Instead, replace the entire ivar with a new unfrozen hash that excludes `after`.
if defined?(ActiveModelSerializers::Railtie)
  ams_init = ActiveModelSerializers::Railtie.initializers
               .find { |i| i.name.to_s == 'active_model_serializers.set_configs' }
  if ams_init
    opts = ams_init.instance_variable_get(:@options) || {}
    ams_init.instance_variable_set(:@options, opts.reject { |k, _| k.to_s == 'after' })
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
