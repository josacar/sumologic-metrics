require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe Worker do
    describe '#init' do
      it 'accepts string keys' do
        queue = Queue.new
        worker = Worker.new(queue, 'secret', 'batch_size' => 100)
        batch = worker.instance_variable_get(:@batch)
        expect(batch.instance_variable_get(:@max_metric_count)).to eq(100)
      end
    end

    describe '#run' do
      it 'does not error if the endpoint is unreachable' do
        response_exception = Response.new(-1, 'Connection error: Wadus Exception')
        allow_any_instance_of(Request).to receive(:post)
          .and_return(response_exception)

        expect do
          queue = Queue.new
          queue << ''
          backoff_policy = BackoffPolicy.new(max_timeout_ms: 0.1, multiplier: 1)
          request = Request.new(uri: 'fakeuri', backoff_policy: backoff_policy)
          worker = Worker.new(queue, 'secret', request: request)
          worker.run

          expect(queue).to be_empty

          allow_any_instance_of(Net::HTTP).to receive(:post).and_call_original
        end.to_not raise_error
      end

      it 'executes the error handler if the request is invalid' do
        allow_any_instance_of(Request).to receive(:post)
          .and_return(Response.new(400, 'Some error'))

        status = message = nil
        on_error = proc do |yielded_status, yielded_message|
          sleep 0.2 # Make this take longer than thread spin-up (below)
          status = yielded_status
          message = yielded_message
        end

        queue = Queue.new
        queue << ''
        worker = described_class.new(queue, 'secret', on_error: on_error)

        # This is to ensure that Client#flush doesn't finish before calling
        # the error handler.
        Thread.new { worker.run }
        sleep 0.1 # First give thread time to spin-up.
        sleep 0.01 while worker.is_requesting?

        allow_any_instance_of(Request).to receive(:post)
          .and_call_original

        expect(queue).to be_empty
        expect(status).to eq(400)
        expect(message).to eq('Some error')
      end

      it 'does not call on_error if the request is good' do
        allow_any_instance_of(Request).to receive(:post)
          .and_return(Response.new(200, 'All good'))

        on_error = proc do |status, message|
          puts "#{status}, #{message}"
        end

        expect(on_error).to_not receive(:call)

        queue = Queue.new
        queue << METRIC
        worker = described_class.new(queue,
                                     'testsecret',
                                     on_error: on_error)
        worker.run

        expect(queue).to be_empty
      end
    end

    describe '#is_requesting?' do
      it 'does not return true if there is no current batch' do
        queue = Queue.new
        worker = Worker.new(queue, 'testsecret')

        expect(worker.is_requesting?).to eq(false)
      end

      it 'returns true if there is a current batch' do
        allow_any_instance_of(Request).to receive(:post) do
          sleep 0.2 # Make this take longer than thread spin-up (below)
          Response.new(400, 'All good')
        end

        queue = Queue.new
        queue << METRIC
        worker = Worker.new(queue, 'testsecret')

        worker_thread = Thread.new { worker.run }
        eventually { expect(worker.is_requesting?).to eq(true) }

        worker_thread.join
        expect(worker.is_requesting?).to eq(false)
      end
    end
  end
end; end
