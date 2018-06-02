require 'sumologic/metrics/backoff_policy'
require 'sumologic/metrics/client'
require 'sumologic/metrics/defaults'
require 'sumologic/metrics/metric'
require 'sumologic/metrics/metric_batch'
require 'sumologic/metrics/logging'
require 'sumologic/metrics/worker'
require 'sumologic/metrics/request'
require 'sumologic/metrics/response'
require 'sumologic/metrics/utils'
require 'sumologic/metrics/version'
require 'sumologic/metrics/worker'

module Sumologic
  class Metrics
    # Initializes a new instance of {Sumologic::Metrics::Client}, to which all
    # method calls are proxied.
    #
    # @param options includes options that are passed down to
    #   {Sumologic::Metrics::Client#initialize}
    # @option options [Boolean] :stub (false) If true, requests don't hit the
    #   server and are stubbed to be successful.
    def initialize(options = {})
      Request.stub = options[:stub] if options.key?(:stub)
      @client = Sumologic::Metrics::Client.new(options)
    end

    def method_missing(message, *args, &block)
      if @client.respond_to?(message)
        @client.send(message, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @client.respond_to?(method_name) || super
    end

    include Logging
  end
end
