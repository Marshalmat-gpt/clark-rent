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

  # Emit GitHub Actions error annotations for every failing example so
  # failures are visible in check-run annotations without log access.
  config.after(:each) do |example|
    next unless example.exception

    file  = example.metadata[:file_path].to_s.sub(%r{^\./}, '')
    line  = example.metadata[:line_number]
    desc  = example.full_description
    msg   = example.exception.message.to_s.split("\n").first(3).join(' | ')
    $stderr.puts "::error file=#{file},line=#{line}::FAIL: #{desc} -- #{msg}"
  end
end
