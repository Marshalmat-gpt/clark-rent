source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Rails API
gem 'rails', '~> 7.2'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'

# Auth
gem 'jwt', '~> 2.7'
gem 'bcrypt', '~> 3.1'

# Storage
gem 'aws-sdk-s3', '~> 1.140', require: false

# Agent IA
gem 'anthropic', '~> 0.3'

# PDF
gem 'prawn', '~> 2.5'
gem 'prawn-table', '~> 0.2'

# Jobs
gem 'sidekiq', '~> 7.2'

# Email
gem 'sendgrid-ruby', '~> 6.7'

# CORS
gem 'rack-cors', '~> 2.0'

# Serialization
gem 'active_model_serializers', '~> 0.10'

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'dotenv-rails'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'shoulda-matchers', '~> 5.3'
end

group :development do
  gem 'rubocop-rails', require: false
end
