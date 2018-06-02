require 'bundler/setup'
require 'sumologic/metrics'

module Sumologic
  class Metrics
    Logging.logger = begin
                       logger = Logger.new(File::NULL)
                       logger.level = Logger::FATAL
                       logger
                     end

    COLLECTOR_URI = 'fakeuri'.freeze
    METRIC = 'cluster=prod node=lb-1 metric=cpu  ip=2.2.3.4 team=infra 80.44654620469632 1528020957'.freeze
  end
end

# A worker that doesn't consume jobs
class NoopWorker
  def run
    # Does nothing
  end
end

# A backoff policy that returns a fixed list of values
class FakeBackoffPolicy
  def initialize(interval_values)
    @interval_values = interval_values
  end

  def next_interval
    raise 'FakeBackoffPolicy has no values left' if @interval_values.empty?
    @interval_values.shift
  end
end

module AsyncHelper
  def eventually(options = {})
    timeout = options[:timeout] || 2
    interval = options[:interval] || 0.1
    time_limit = Time.now + timeout
    loop do
      begin
        yield
        return
      rescue RSpec::Expectations::ExpectationNotMetError => error
        raise error if Time.now >= time_limit
        sleep interval
      end
    end
  end
end

include AsyncHelper

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
