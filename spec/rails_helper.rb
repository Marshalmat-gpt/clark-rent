require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

begin
  require_relative '../config/environment'
rescue => e
  warn "\n=== RAILS BOOT ERROR ===\n#{e.class}: #{e.message}\n" \
       e.backtrace.first(10).join("\n") +
       "\n========================\n"
  raise
end

require 'rspec/rails'
require 'factory_bot_rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
