require 'sumologic/metrics/defaults'
require 'sumologic/metrics/utils'
require 'sumologic/metrics/response'
require 'sumologic/metrics/logging'
require 'sumologic/metrics/backoff_policy'
require 'net/http'
require 'net/https'
require 'uri'

module Sumologic; class Metrics
  class Request
    include Sumologic::Metrics::Defaults::Request
    include Sumologic::Metrics::Utils
    include Sumologic::Metrics::Logging

    # public: Creates a new request object to send metrics batch
    #
    def initialize(options = {})
      @headers = options[:headers] || HEADERS
      @retries = options[:retries] || RETRIES
      @backoff_policy =
        options[:backoff_policy] || Sumologic::Metrics::BackoffPolicy.new

      uri = URI(options.fetch(:uri))
      http = Net::HTTP.new(uri.host, uri.port)
      http.set_debug_output(logger) if logger.level == Logger::DEBUG
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = 8
      http.open_timeout = 4

      @path = uri.path
      @http = http
    end

    # public: Posts the write key and batch of messages to the API.
    #
    # returns - Response of the status and error if it exists
    def post(batch)
      last_response, exception = retry_with_backoff(@retries) do
        status_code, body, message = send_request(batch)

        should_retry = should_retry_request?(status_code, body)

        [Response.new(status_code, message), should_retry]
      end

      if exception
        logger.error(exception.message)
        exception.backtrace.each { |line| logger.error(line) }
        Response.new(-1, "Connection error: #{exception}")
      else
        last_response
      end
    end

    private

    def should_retry_request?(status_code, body)
      if status_code >= 500
        true # Server error
      elsif status_code == 429
        true # Rate limited
      elsif status_code >= 400
        logger.error(body)
        false # Client error. Do not retry, but log
      else
        false
      end
    end

    # Takes a block that returns [result, should_retry].
    #
    # Retries upto `retries_remaining` times, if `should_retry` is false or
    # an exception is raised. `@backoff_policy` is used to determine the
    # duration to sleep between attempts
    #
    # Returns [last_result, raised_exception]
    def retry_with_backoff(retries_remaining, &block)
      result, caught_exception = nil
      should_retry = false

      begin
        result, should_retry = yield
        return [result, nil] unless should_retry
      rescue StandardError => e
        p e
        should_retry = true
        caught_exception = e
      end

      if should_retry && (retries_remaining > 1)
        sleep(@backoff_policy.next_interval.to_f / 1000)
        retry_with_backoff(retries_remaining - 1, &block)
      else
        [result, caught_exception]
      end
    end

    # Sends a request for the batch, returns [status_code, body]
    def send_request(batch)
      payload = batch.to_s
      request = Net::HTTP::Post.new(@path, @headers)

      if self.class.stub
        logger.debug "stubbed request to #{@path}: " \
          "batch = '#{batch}'"

        [200, '', 'OK']
      else
        # If `start` is not called, Ruby adds a 'Connection: close' header to
        # all requests, preventing us from reusing a connection for multiple
        # HTTP requests
        @http.start unless @http.started?

        response = @http.request(request, payload)
        [response.code.to_i, response.body, response.message]
      end
    end

    class << self
      attr_writer :stub

      def stub
        @stub || ENV['STUB']
      end
    end
  end
end; end
