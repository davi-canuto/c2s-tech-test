require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module C2sTechTest
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths += %W[#{config.root}/app/parsers]
    config.eager_load_paths += %W[#{config.root}/app/parsers]

    config.autoload_paths += %W[#{config.root}/app/presenters]
    config.eager_load_paths += %W[#{config.root}/app/presenters]

    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.available_locales = [ :en ]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    # Configure Sidekiq as the ActiveJob queue adapter
    config.active_job.queue_adapter = :sidekiq
  end
end
