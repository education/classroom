# frozen_string_literal: true

# Helpers
tap "caskroom/cask"
tap "github/bootstrap"

cask "java8"
cask "ngrok"

brew "nodejs"
brew "terminal-notifier"

brew "elasticsearch@1.7", restart_service: :changed
brew "memcached",         restart_service: :changed
brew "nginx",             restart_service: :changed
brew "postgresql",        restart_service: :changed
brew "redis",             restart_service: :changed
