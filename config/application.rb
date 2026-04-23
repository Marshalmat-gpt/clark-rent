require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Fix FrozenError: Rails 7.2 + Zeitwerk freezes ActiveSupport::Dependencies.autoload_paths
# before all engine initializers run. AMS 0.10.16's inherited Engine initializer calls
# autoload_paths.unshift() which raises FrozenError on the frozen array.
# Prevent freeze by defining a no-op singleton method on both path arrays.
if defined?(ActiveSupport::Dependencies)
  [ActiveSupport::Dependencies.autoload_paths,
   ActiveSupport::Dependencies.autoload_once_paths].each do |arr|
    arr.define_singleton_method(:freeze) { self }
  end
end

# Fix TSort::Cyclic: AMS 0.10.16 registers 'active_model_serializers.set_configs'
# with after: 'action_controller.set_configs', which creates a cyclic dependency
# in Rails 7.2's initializer tsort graph.
# This fix removes the problematic initializer before initialize! builds the tsort graph.
# AMS logger/caching wiring is handled separately in ams_logger.rb.
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
