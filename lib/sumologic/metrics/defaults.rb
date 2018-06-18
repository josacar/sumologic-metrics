require 'sumologic/metrics/version'

module Sumologic; class Metrics; module Defaults
  module Request
    HEADERS = {
      'Content-Type' => 'application/vnd.sumologic.carbon2',
      'User-Agent' => "sumologic-metrics/#{Sumologic::Metrics::VERSION}"
    }.freeze
    RETRIES = 10
  end

  module Queue
    MAX_SIZE = 10_000
  end

  module Metric
    MAX_BYTES = 32_768 # 32Kb
  end

  module MetricBatch
    MAX_BYTES = 512_000 # 500Kb
    MAX_SIZE = 100
  end

  module BackoffPolicy
    MIN_TIMEOUT_MS = 100
    MAX_TIMEOUT_MS = 10_000
    MULTIPLIER = 1.5
    RANDOMIZATION_FACTOR = 0.5
  end
end; end; end
