source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

gem 'rails', '~> 7.1'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'
gem 'jwt', '~> 2.7'
gem 'bcrypt', '~> 3.1'
gem 'aws-sdk-s3', '~> 1.140', require: false
gem 'anthropic', '~> 0.3'
gem 'prawn', '~> 2.5'
gem 'prawn-table', '~> 0.2'
gem 'sidekiq', '~> 7.2'
gem 'sendgrid-ruby', '~> 6.7'
gem 'rack-cors', '~> 2.0'
gem 'active_model_serializers', '~> 0.10'

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'dotenv-rails'
end

group :development do
  gem 'rubocop-rails', require: false
end
