require 'logger'

module Sumologic; class Metrics; module Logging
  class << self
    def logger
      @logger ||= begin
                    logger = Logger.new(STDOUT)
                    logger.level = Logger::INFO
                    logger.progname = 'Sumologic::Metrics'
                    logger
                  end
    end

    attr_writer :logger
  end

  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    Logging.logger
  end
end; end; end
