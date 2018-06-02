module Sumologic; class Metrics
  class Response
    attr_reader :status, :message

    # public: Simple class to wrap responses from the API
    #
    #
    def initialize(status = 200, message = nil)
      @status = status
      @message = message
    end
  end
end; end
