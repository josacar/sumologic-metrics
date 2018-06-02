require 'sumologic/metrics/defaults'
require 'sumologic/metrics/metric'
require 'sumologic/metrics/metric_batch'
require 'sumologic/metrics/request'
require 'sumologic/metrics/utils'

module Sumologic; class Metrics
  class Worker
    include Sumologic::Metrics::Utils
    include Sumologic::Metrics::Defaults

    # public: Creates a new worker
    #
    # The worker continuously takes metrics off the queue
    # and makes requests to the Sumologic api
    #
    # queue   - Queue synchronized between client and worker
    # collector_uri  - String of the unique collector URI
    # options - Hash of worker options
    #           batch_size - Fixnum of how many items to send in a batch
    #           on_error   - Proc of what to do on an error
    #
    def initialize(queue, collector_uri, options = {})
      symbolize_keys! options
      @queue = queue
      @collector_uri = collector_uri
      @on_error = options[:on_error] || proc { |status, message| }
      batch_size = options[:batch_size] || Defaults::MetricBatch::MAX_SIZE
      @batch = MetricBatch.new(batch_size)
      @lock = Mutex.new
      @request = options[:request] || Request.new(uri: collector_uri)
    end

    # public: Continuously runs the loop to check for new events
    #
    def run
      until Thread.current[:should_exit]
        return if @queue.empty?

        @lock.synchronize do
          until @batch.full? || @queue.empty?
            @batch << Metric.new(@queue.pop)
          end
        end

        res = @request.post(@batch)
        @on_error.call(res.status, res.message) unless res.status == 200

        @lock.synchronize { @batch.clear }
      end
    end

    # public: Check whether we have outstanding requests.
    #
    def is_requesting?
      @lock.synchronize { !@batch.empty? }
    end
  end
end; end
