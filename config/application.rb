require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Fix TSort::Cyclic caused by active_model_serializers 0.10.x on Rails 7.2+.
#
# Rails 7.2's railties_initializers calls r.initializers where r is a railtie
# INSTANCE (via Railtie.instance). The AMS 'set_configs' initializer declares
# after: 'action_controller.set_configs', creating a cycle in the tsort graph.
#
# We prepend to the class (not singleton_class) so the INSTANCE method
# `initializers` is overridden — that is the method Rails actually invokes
# when collecting initializers from each railtie instance.
#
# AMS logger is wired separately via config/initializers/ams_logger.rb.
if defined?(ActiveModelSerializers::Railtie)
  ActiveModelSerializers::Railtie.prepend(Module.new do
    def initializers
      super.reject { |i| i.name.to_s == 'active_model_serializers.set_configs' }
    end
  end)
end

module ClarkRent
  class Application < Rails::Application
    config.load_defaults 7.2
    config.api_only = true
    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
  end
end
