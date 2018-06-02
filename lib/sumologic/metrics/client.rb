require 'thread'
require 'time'

require 'sumologic/metrics/defaults'
require 'sumologic/metrics/logging'
require 'sumologic/metrics/utils'
require 'sumologic/metrics/worker'

module Sumologic; class Metrics
  class Client
    include Sumologic::Metrics::Utils
    include Sumologic::Metrics::Logging

    # @param [Hash] opts
    # @option opts [String] :collector_uri Your project's collector_uri
    # @option opts [FixNum] :max_queue_size Maximum number of calls to be
    #   remain queued.
    # @option opts [Proc] :on_error Handles error calls from the API.
    def initialize(opts = {})
      symbolize_keys!(opts)

      @queue = Queue.new
      @collector_uri = opts[:collector_uri]
      @max_queue_size = opts[:max_queue_size] || Defaults::Queue::MAX_SIZE
      @options = opts
      @worker_mutex = Mutex.new
      @worker = Worker.new(@queue, @collector_uri, @options)

      check_collector_uri!

      at_exit { @worker_thread && @worker_thread[:should_exit] = true }
    end

    # Synchronously waits until the worker has flushed the queue.
    #
    # Use only for scripts which are not long-running, and will specifically
    # exit
    def flush
      while !@queue.empty? || @worker.is_requesting?
        ensure_worker_running
        sleep(0.1)
      end
    end

    # Pushes a metric
    #
    # @see https://help.sumologic.com/Send-Data/Sources/02Sources-for-Hosted-Collectors/HTTP-Source/Upload-Data-to-an-HTTP-Source#About_the_Carbon_2.0_example_data_points
    #
    # @param [String] metric
    def push(metric)
      check_presence!(metric)
      check_carbon_format!(metric)

      enqueue(metric)
    end

    # @return [Fixnum] number of metrics in the queue
    def queued_metrics
      @queue.length
    end

    private

    # private: Enqueues the action.
    #
    # returns Boolean of whether the item was added to the queue.
    def enqueue(metric)
      if @queue.length < @max_queue_size
        @queue << metric
        ensure_worker_running

        true
      else
        logger.warn(
          'Queue is full, dropping events. The :max_queue_size ' \
          'configuration parameter can be increased to prevent this from ' \
          'happening.'
        )
        false
      end
    end

    # private: Ensures that a string is non-empty
    #
    # obj    - String|Number that must be non-blank
    #
    def check_presence!(obj)
      if obj.nil? || (obj.is_a?(String) && obj.empty?)
        raise ArgumentError, 'metric must be given'
      end
    end

    # private: Checks that the collector_uri is properly initialized
    def check_collector_uri!
      raise ArgumentError, 'collector URI must be initialized' if @collector_uri.nil?
    end

    # private: Checks the metric is Carbon 2
    def check_carbon_format!(metric)
      tag = '[^\s]+=[^\s]+'
      intrinsic_tags = "(?<intrinsic_tags>#{tag}(?: #{tag})+)"
      meta_tags = "(?<meta_tags>#{tag}(?:\s#{tag})*)"
      value = '(?<value>[\d|\.]+)'
      timestamp = '(?<timestamp>\d+)'
      r = Regexp.new(/#{intrinsic_tags}  (?:#{meta_tags}\s)?#{value} #{timestamp}/)
      raise ArgumentError, 'metric should be in Carbon 2 format' unless r.match?(metric)
    end


    def ensure_worker_running
      return if worker_running?
      @worker_mutex.synchronize do
        return if worker_running?
        @worker_thread = Thread.new do
          @worker.run
        end
      end
    end

    def worker_running?
      @worker_thread && @worker_thread.alive?
    end
  end
end; end
