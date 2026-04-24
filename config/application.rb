require_relative 'boot'

# Selective requires for API-only mode — excludes ActionView, ActionCable,
# ActiveStorage, ActionMailbox, and ActionText, none of which are used by
# this API. Crucially, each excluded component registers its own engine
# migration directory via an `append_migrations` initializer; keeping them
# out of the boot sequence ensures `db:migrate` only touches db/migrate/.
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)

# Compatibility fix for AMS 0.10.16 + Rails 7.2:
# Rails 7.2 freezes ActiveSupport::Dependencies.autoload_paths (via Zeitwerk
# setup) before all engine initializers run. Intercept the setter so any
# newly assigned array also gets a no-op freeze singleton.
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

# Fix TSort::Cyclic: AMS 0.10.16 'active_model_serializers.set_configs'
# initializer declares after: 'action_controller.set_configs', creating a
# cycle in Rails 7.2's initializer tsort graph. Remove it before initialize!
# builds the graph. AMS logger wiring lives in config/initializers/ams_logger.rb.
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

    # Fix FrozenError at railties/engine.rb:
    # Rails 7.2 freezes routes_reloader.paths before AMS 0.10.16's inherited
    # Engine add_routing_paths initializer calls unshift() on it.
    # Running before :add_routing_paths ensures the no-op freeze is in place first.
    # If paths is already frozen by this point, replace the paths accessor on
    # the reloader instance with an unfrozen dup so AMS can unshift into it.
    initializer :fix_routes_reloader_freeze, before: :add_routing_paths do |app|
      begin
        paths = app.routes_reloader.paths
        if paths.frozen?
          mutable = paths.dup
          mutable.define_singleton_method(:freeze) { self }
          reloader = app.routes_reloader
          reloader.define_singleton_method(:paths) { mutable }
        else
          paths.define_singleton_method(:freeze) { self }
        end
      rescue => e
        warn "[clark-rent] fix_routes_reloader_freeze skipped: #{e.class}: #{e.message}"
      end
    end
  end
end
