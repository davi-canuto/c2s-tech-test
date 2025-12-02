require 'spec_helper'
ENV['RAILS_ENV'] = 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'database_cleaner/active_record'
require 'shoulda/matchers'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Dir[Rails.root.join('app/parsers/**/*.rb')].each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    raise "Running tests in #{Rails.env} environment!" unless Rails.env.test?

    db_config = ActiveRecord::Base.connection_db_config
    db_name = db_config.database
    unless db_name.to_s.include?('_test')
      raise "Connected to wrong database: #{db_name}. Expected test database!"
    end

    DatabaseCleaner.allow_remote_database_url = true
    DatabaseCleaner[:active_record].strategy = :transaction
    DatabaseCleaner[:active_record].clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each, type: :request) do
    host! 'www.example.com'
  end

  # Allow all hosts in test environment
  config.before(:each) do
    allow(ActionDispatch::HostAuthorization).to receive(:new).and_call_original
  end
end
