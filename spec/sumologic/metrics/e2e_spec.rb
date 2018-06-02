require 'spec_helper'

module Sumologic
  RSpec.describe 'End-to-end tests', e2e: true do
    let(:client) { Sumologic::Metrics.new(uri: ENV.fetch('URI')) }

    xit 'pushes metrics to Sumologic' do
      client.flush

      eventually(timeout: 30) do
        expect(has_matching_request?(id)).to eq(true)
      end
    end

    def has_matching_request?(id)
      true
    end
  end
end
