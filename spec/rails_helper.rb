require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'

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

  # Diagnostic: emit which user tables exist when the suite starts.
  # Confirms whether db:migrate created tables before rspec runs.
  config.before(:suite) do
    begin
      tables = ActiveRecord::Base.connection.tables.sort
                                 .reject { |t| %w[schema_migrations ar_internal_metadata].include?(t) }
      if tables.empty?
        $stderr.puts '::error::DB_SCHEMA_EMPTY: No user tables at suite start — db:migrate may not have run'
      else
        $stderr.puts "::notice::DB_TABLES_AT_START: #{tables.join(', ')}"
      end
    rescue => e
      $stderr.puts "::error::DB_CONNECT_ERROR: #{e.class}: #{e.message.split(%r{\n}).first}"
    end
  end

  # Emit GitHub Actions error annotations for every failing example so
  # failures are visible in check-run annotations without log access.
  config.after(:each) do |example|
    next unless example.exception

    file  = example.metadata[:file_path].to_s.sub(%r{^\./}, '')
    line  = example.metadata[:line_number]
    desc  = example.full_description
    msg   = example.exception.message.to_s.split(%r{\n}).first(3).join(' | ')
    $stderr.puts "::error file=#{file},line=#{line}::FAIL: #{desc} -- #{msg}"
  end
end
