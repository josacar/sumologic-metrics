require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe MetricBatch do
    subject { described_class.new(100) }

    describe '#<<' do
      it 'appends metrics' do
        subject << Metric.new('metric')
        expect(subject.length).to eq(1)
      end

      it 'rejects metrics that exceed the maximum allowed size' do
        max_bytes = Defaults::Metric::MAX_BYTES
        metric = Metric.new('metric' * max_bytes)

        subject << metric
        expect(subject.length).to eq(0)
      end
    end

    describe '#full?' do
      it 'returns true once item count is exceeded' do
        99.times { subject << Metric.new('metric') }
        expect(subject.full?).to be(false)

        subject << Metric.new('metric')
        expect(subject.full?).to be(true)
      end

      it 'returns true once max size is almost exceeded' do
        metric = Metric.new('m' * (Defaults::Metric::MAX_BYTES - 10))

        # Each metric is under the individual limit
        expect(metric.size).to be < Defaults::Metric::MAX_BYTES

        # Size of the batch is over the limit
        expect(50 * metric.size).to be > Defaults::MetricBatch::MAX_BYTES

        expect(subject.full?).to be(false)
        50.times { subject << metric }
        expect(subject.full?).to be(true)
      end
    end
  end
end; end
