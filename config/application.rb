require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Compatibility fix for AMS 0.10.16 + Rails 7.2:
# Rails 7.2 freezes ActiveSupport::Dependencies.autoload_paths (via Zeitwerk setup)
# before all engine initializers run. Intercept the setter so any newly assigned
# array also gets a no-op freeze singleton. Belt-and-suspenders: patch current arrays too.
if defined?(ActiveSupport::Dependencies)
  ActiveSupport::Dependencies.singleton_class.prepend(Module.new do
    def autoload_paths=(val)
      super
      autoload_paths.define_singleton_method(:freeze) { self } rescue nil
    end
    def autoload_once_paths=(val)
      super
      autoload_once_paths.define_singleton_method(:freeze) { self } rescue nil
    end
  end)
  begin; ActiveSupport::Dependencies.autoload_paths.define_singleton_method(:freeze) { self }; rescue; end
  begin; ActiveSupport::Dependencies.autoload_once_paths.define_singleton_method(:freeze) { self }; rescue; end
end

# Fix TSort::Cyclic: AMS 0.10.16 'active_model_serializers.set_configs' initializer
# declares after: 'action_controller.set_configs', creating a cycle in Rails 7.2's
# initializer tsort graph. Remove it before initialize! builds the graph.
# AMS logger wiring is handled separately in config/initializers/ams_logger.rb.
if defined?(ActiveModelSerializers::Railtie)
  ActiveModelSerializers::Railtie.class_eval do
    if @initializers
      bad = 'active_model_serializers.set_configs'
      begin
        @initializers.reject! { |i| i.name.to_s == bad }
      rescue FrozenError, RuntimeError
        new_col = @initializers.class.new
        @initializers.each { |i| new_col << i unless i.name.to_s == bad }
        @initializers = new_col
      end
    end
  end
end

module ClarkRent
  class Application < Rails::Application
    config.load_defaults 7.2
    config.api_only = true
    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr

    # Fix FrozenError at railties/engine.rb:598:
    # Rails 7.2 freezes routes_reloader.paths before AMS 0.10.16's inherited Engine
    # add_routing_paths initializer calls unshift() on it.
    # Running before :add_routing_paths ensures the no-op freeze is in place first.
    initializer :fix_routes_reloader_freeze, before: :add_routing_paths do |app|
      app.routes_reloader.paths.define_singleton_method(:freeze) { self }
    end
  end
end
