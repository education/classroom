require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Classroom
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Add bower assets to the path
    root.join('vendor', 'assets', 'bower_components').to_s.tap do |bower_path|
      config.sass.load_paths << bower_path
      config.assets.paths << bower_path
    end

    # Append directories to autoload paths
    config.autoload_paths += Dir["#{Rails.root}/lib"]

    # Precompile Fonts
    # Compile all font types except octicons-local
    config.assets.precompile << %r(octicons/octicons/octicons+\.(?:svg|eot|woff|ttf)$)

    # Configure the generators
    config.generators do |g|
      g.test_framework :rspec, fixture: false
    end

    # GC Profiler for analytics
    GC::Profiler.enable

    # Use SideKiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Health checks endpoint for monitoring
    if ENV['PINGLISH_ENABLED'] == 'true'
      config.middleware.use Pinglish do |ping|
        ping.check :db do
          ActiveRecord::Base.connection.tables.size
          'ok'
        end

        ping.check :memcached do
          Rails.cache.dalli.checkout.alive!
          'ok'
        end

        ping.check :redis do
          Sidekiq.redis { |redis| redis.ping }
          'ok'
        end
      end
    end

    #Setting invoked exceptions application for custom 404 error pages
    config.exceptions_app = self.routes

  end
end
