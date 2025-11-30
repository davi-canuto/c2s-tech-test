source "https://rubygems.org"
# ruby version setted on Dockerfile

gem "rails", "~> 8.0.2", ">= 8.0.2.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "redis", "~> 5.0"
gem "mail", "~> 2.8"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "sidekiq", "~> 8.0"
gem "cssbundling-rails", "~> 1.4"
gem "importmap-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "turbo-rails", "~> 2.0"
gem "pagy", "~> 9.0"
gem "ransack", "~> 4.0"

group :development, :test do
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails", "~> 6.0"
  gem "faker", "~> 3.0"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.0"
  gem "simplecov", "~> 0.22", require: false
end