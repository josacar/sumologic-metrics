require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe Metrics do
    let(:metrics) { Metrics.new(collector_uri: COLLECTOR_URI, stub: true) }

    describe '#push' do
      it 'does not error with the required options' do
        expect do
          metrics.push(METRIC)
          sleep(1)
        end.to_not raise_error
      end
    end

    describe '#flush' do
      it 'flushes without error' do
        expect do
          metrics.push(METRIC)
          metrics.flush
        end.to_not raise_error
      end
    end

    describe '#respond_to?' do
      it 'responds to all public instance methods of Sumologic::Metrics::Client' do
        expect(metrics).to respond_to(*Sumologic::Metrics::Client.public_instance_methods(false))
      end
    end

    describe '#method' do
      Sumologic::Metrics::Client.public_instance_methods(false).each do |public_method|
        it "returns a Method object with '#{public_method}' as argument" do
          expect(metrics.method(public_method).class).to eq(Method)
        end
      end
    end
  end
end; end
