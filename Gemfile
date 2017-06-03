# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.1'
gem 'rails', '~> 5.1', '>= 5.1.1'

gem 'chewy', '~> 0.9.0'

gem 'dalli'

gem 'faraday-http-cache'
gem 'flipper'
gem 'flipper-redis'
gem 'flipper-ui'

gem 'geo_pattern'

gem 'kaminari'

gem 'octicons_helper', '~> 2.1'
gem 'octokit'
gem 'omniauth'
gem 'omniauth-github'

gem 'peek', '~> 1.0', '>= 1.0.1'
gem 'peek-dalli', github: 'peek/peek-dalli', ref: '0a68e1fc73095a421dc2cae3d23937bb1cbb027c'
gem 'peek-gc'
gem 'peek-git'
gem 'peek-performance_bar'
gem 'peek-pg',      github: 'mkcode/peek-pg',      ref: '9bbe212ed1b6b4a4ad56ded1ef4cf9179cdac0cd'
gem 'peek-sidekiq', github: 'Soliah/peek-sidekiq', ref: '261c857578ae6dc189506a35194785a4db51e54c'
gem 'pg'
gem 'pry-byebug'
gem 'pry-rails'
gem 'puma', '~> 3.9'

gem 'rack-canonical-host'
gem 'rack-timeout', require: false
gem 'rails-i18n', '~> 5.0', '>= 5.0.1'
gem 'redis-namespace'
gem 'ruby-progressbar', '~> 1.8', '>= 1.8.1', require: false

gem 'sidekiq', '~> 5.0'

gem 'typhoeus', '~> 1.1', '>= 1.1.2'

gem 'webpacker'

group :development do
  gem 'foreman'
  gem 'web-console'
end

group :development, :test do
  gem 'awesome_print', require: 'ap'
  gem 'bullet'
  gem 'dotenv-rails'
  gem 'guard-rspec', require: false
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'scss_lint', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'terminal-notifier-guard'
  gem 'timecop', require: false
end

group :production do
  gem 'airbrake'
  gem 'lograge', '~> 0.5.1'
  gem 'newrelic_rpm'
  gem 'pinglish'
  gem 'puma_worker_killer'
  gem 'rack-tracker'
  gem 'rails_12factor'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end
