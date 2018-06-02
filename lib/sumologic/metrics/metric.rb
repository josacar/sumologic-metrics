require 'sumologic/metrics/defaults'

module Sumologic; class Metrics
  class Metric
    def initialize(content)
      @content = content
    end

    def too_big?
      size > Defaults::Metric::MAX_BYTES
    end

    def size
      @content.bytesize
    end

    def to_s
      @content
    end
  end
end; end
