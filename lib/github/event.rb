# frozen_string_literal: true

module GitHub
  class Event
    attr_accessor :event_client

    def initialize(access_token, options = { auto_paginate: false })
      options[:access_token] = access_token

      @event_client = Octokit::Client.new(options)
    end

    def latest_push_event(repo_id, options = { per_page: 100, page: 1 })
      events = event_client.repository_events(repo_id, options).select do |event|
        event.type == 'PushEvent' || (event.type == 'CreateEvent' && event.payload.ref.present?)
      end

      events.first
    end
  end
end
