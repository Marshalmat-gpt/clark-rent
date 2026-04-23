require_relative 'boot'
require 'rails/all'
Bundler.require(*Rails.groups)

# Fix TSort::Cyclic: AMS 0.10.16 registers 'active_model_serializers.set_configs'
# with after: 'action_controller.set_configs', which creates a cyclic dependency
# in Rails 7.2's initializer tsort graph.
#
# Method-override approaches (singleton_class.prepend, prepend) do not work
# because Rails 7.2 accesses @initializers directly via ivar in some internal
# code paths, bypassing the public `initializers` method entirely.
#
# This fix uses class_eval to reach the class-level @initializers ivar and
# removes the problematic entry before initialize! builds the tsort graph.
# AMS logger/caching wiring is handled separately in ams_logger.rb.
if defined?(ActiveModelSerializers::Railtie)
  ActiveModelSerializers::Railtie.class_eval do
    if @initializers
      bad = 'active_model_serializers.set_configs'
      begin
        @initializers.reject! { |i| i.name.to_s == bad }
      rescue FrozenError, RuntimeError
        # Collection is frozen — swap it out for an unfrozen replacement
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
