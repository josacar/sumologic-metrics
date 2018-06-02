require 'forwardable'
require 'sumologic/metrics/logging'

module Sumologic; class Metrics
  # A batch of `metric`s to be sent to the API
  class MetricBatch
    extend Forwardable
    include Sumologic::Metrics::Logging
    include Sumologic::Metrics::Defaults::MetricBatch

    def initialize(max_metric_count)
      @metrics = []
      @max_metric_count = max_metric_count
      @size = 0
    end

    def <<(metric)
      if metric.too_big?
        logger.error('a metric exceeded the maximum allowed size')
      else
        @metrics << metric
        @size += metric.size + 2 # One byte for new line
      end
    end

    def full?
      item_count_exhausted? || size_exhausted?
    end

    def clear
      @metrics.clear
      @json = 0
    end

    def to_s
      @metrics.join("\n")
    end

    def_delegators :@metrics, :empty?
    def_delegators :@metrics, :length

    private

    def item_count_exhausted?
      @metrics.length >= @max_metric_count
    end

    # We consider the max size here as just enough to leave room for one more
    # metric of the largest size possible. This is a shortcut that allows us
    # to use a native Ruby `Queue` that doesn't allow peeking. The tradeoff
    # here is that we might fit in less metrics than possible into a batch.
    #
    # The alternative is to use our own `Queue` implementation that allows
    # peeking, and to consider the next metric size when calculating whether
    # the metric can be accomodated in this batch.
    def size_exhausted?
      @size >= (MAX_BYTES - Defaults::Metric::MAX_BYTES)
    end
  end
end; end
