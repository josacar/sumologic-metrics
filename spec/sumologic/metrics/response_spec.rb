require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe Response do
    describe '#status' do
      it { expect(subject).to respond_to(:status) }
    end

    describe '#message' do
      it { expect(subject).to respond_to(:message) }
    end

    describe '#initialize' do
      let(:status) { 400 }
      let(:message) { 'Invalid metrics' }

      subject { described_class.new(status, message) }

      it 'sets the instance variable status' do
        expect(subject.instance_variable_get(:@status)).to eq(status)
      end

      it 'sets the instance variable message' do
        expect(subject.instance_variable_get(:@message)).to eq(message)
      end
    end
  end
end; end
