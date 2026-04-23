require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Compatibility fix for AMS 0.10.16 + Rails 7.2 (Zeitwerk):
# Rails 7.2 reassigns ActiveSupport::Dependencies.autoload_paths to a new array
# during initialize! and freezes it. AMS's Engine initializer then calls unshift()
# on the frozen array => FrozenError at railties/engine.rb:579.
#
# Fix: prepend to the singleton class so every future assignment also gets a
# no-op freeze singleton. Also patch the current arrays immediately.
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

# Fix TSort::Cyclic: AMS 0.10.16 registers 'active_model_serializers.set_configs'
# with after: 'action_controller.set_configs', which creates a cyclic dependency
# in Rails 7.2's initializer tsort graph.
# Removes the problematic initializer before initialize! builds the tsort graph.
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
  end
end
