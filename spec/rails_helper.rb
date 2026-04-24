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

  config.before(:suite) do
    begin
      tables = ActiveRecord::Base.connection.tables.sort
                                 .reject { |t| %w[schema_migrations ar_internal_metadata].include?(t) }
      if tables.empty?
        $stderr.puts '::notice::DB_SCHEMA_EMPTY: loading db/schema.rb'
        load Rails.root.join('db', 'schema.rb')
      else
        $stderr.puts "::notice::DB_TABLES_AT_START: #{tables.join(', ')}"
      end
    rescue => e
      $stderr.puts "::error::DB_CONNECT_ERROR: #{e.class}: #{e.message.split(%r{\n}).first}"
      raise
    end
  end

  # Emit GitHub Actions error annotations per failing example
  config.after(:each) do |example|
    next unless example.exception
    file  = example.metadata[:file_path].to_s.sub(%r{^\./}, '')
    line  = example.metadata[:line_number]
    desc  = example.full_description
    msg   = example.exception.message.to_s.split(%r{\n}).first(3).join(' | ')
    $stderr.puts "::error file=#{file},line=#{line}::FAIL: #{desc} -- #{msg}"
  end
end
