require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe Sumologic::Metrics::Client do
    let(:client) do
      Client.new(collector_uri: COLLECTOR_URI).tap do |client|
        # Ensure that worker doesn't consume items from the queue
        client.instance_variable_set(:@worker, NoopWorker.new)
      end
    end
    let(:queue) { client.instance_variable_get :@queue }

    describe '#initialize' do
      it 'errors if no collector_uri is supplied' do
        expect { described_class.new }.to raise_error(ArgumentError)
      end

      it 'does not error if a collector_uri is supplied' do
        expect do
          Client.new(collector_uri: COLLECTOR_URI)
        end.to_not raise_error
      end

      it 'does not error if a collector_uri is supplied as a string' do
        expect do
          Client.new('collector_uri' => COLLECTOR_URI)
        end.to_not raise_error
      end
    end

    describe '#push' do
      it 'errors without a metric' do
        expect { client.push(nil) }.to raise_error(ArgumentError)
      end

      it 'errors when metric is not in Carbon 2.0 format' do
        expect { client.push('wadus') }.to raise_error(ArgumentError)
      end

      it 'does not error with the required options' do
        expect do
          client.push(METRIC)
          queue.pop
        end.to_not raise_error
      end
    end

    describe '#flush' do
      let(:client_with_worker) { Client.new(collector_uri: COLLECTOR_URI) }
      before do
        allow_any_instance_of(Sumologic::Metrics::Request).to receive(:post)
          .and_return(Sumologic::Metrics::Response.new(200, 'All good'))
      end

      it 'waits for the queue to finish on a flush' do
        client_with_worker.push(METRIC)
        client_with_worker.flush

        expect(client_with_worker.queued_metrics).to eq(0)
      end

      unless defined? JRUBY_VERSION
        it 'completes when the process forks' do
          client_with_worker.push(METRIC)

          Process.fork do
            client_with_worker.push(METRIC)
            client_with_worker.flush
            expect(client_with_worker.queued_metrics).to eq(0)
          end

          Process.wait
        end
      end
    end

    context 'common' do
      it 'returns false if queue is full' do
        client.instance_variable_set(:@max_queue_size, 1)
        expect(client.push(METRIC)).to eq(true)
        expect(client.push(METRIC)).to eq(false) # Queue is full
        queue.pop(true)
      end
    end
  end
end; end
