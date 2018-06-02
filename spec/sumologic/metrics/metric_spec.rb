require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe Metric do
    describe '#too_big?' do
      it 'returns false when metric is below MAX_BYTES' do
        metric = 'a' * Defaults::Metric::MAX_BYTES
        expect(Metric.new(metric).too_big?).to eq(false)
      end

      it 'returns true when metric exceeeds MAX_BYTES' do
        metric = 'a' * Defaults::Metric::MAX_BYTES
        expect(Metric.new(metric).too_big?).to eq(false)
        metric << 'a'
        expect(Metric.new(metric).too_big?).to eq(true)
      end
    end
  end
end; end
