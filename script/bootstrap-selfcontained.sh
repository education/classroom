#!/bin/bash

# Usage: script/setup-selfcontained.sh
# Runs bootstrap for the self-contained docker profile, where
#   ruby itself is also part of the docker-compose stack

# This script gets run by the dockerfile itself to install dependencies, etc.
# It assumes we are on debian jessie, as that is the ruby:2.4.2 image base

set -e

# install ruby with rbenv if necessary (should not be if dockerfile is correctly updated)
RUBYVERSION=$(cat .ruby-version)
RUBYVERSION_INSTALLED=$(ruby -v)
if [ $RUBYVERSION_INSTALLED != $RUBYVERSION ]; then
  rbenv install $(cat .ruby-version)
  rbenv global $(cat .ruby-version)
fi
#install updated bundler
gem install bundler -v "<2.0"

# install gems
bundle check 2>&1 || {
  echo "==> Installing gem dependencies..."
  bundle install --local --without production
}

#install yarn dependencies
yarnpkg install
