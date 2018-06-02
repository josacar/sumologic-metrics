require 'spec_helper'

module Sumologic; class Metrics
  RSpec.describe Request do
    let(:uri) { 'https://fakehost/receiver/v1/http/fake_code' }
    subject { described_class.new(uri: uri) }

    describe '#initialize' do
      let!(:net_http) { Net::HTTP.new(anything, anything) }

      before do
        allow(Net::HTTP).to receive(:new).and_return(net_http)
      end

      it 'sets an initalized Net::HTTP use_ssl' do
        expect(net_http).to receive(:use_ssl=)
        subject
      end

      it 'sets an initalized Net::HTTP read_timeout' do
        expect(net_http).to receive(:read_timeout=)
        subject
      end

      it 'sets an initalized Net::HTTP open_timeout' do
        expect(net_http).to receive(:open_timeout=)
        subject
      end

      it 'sets the http client debug when log level is debug' do
        old_log_level = Logging.logger.level
        Logging.logger.level = Logger::DEBUG
        expect(net_http).to receive(:set_debug_output).with(Logging.logger)

        subject

        Logging.logger.level = old_log_level
      end

      it 'does not set http client debug when log level is not debug' do
        expect(net_http).not_to receive(:set_debug_output)
        subject
      end

      it 'sets the http client' do
        expect(subject.instance_variable_get(:@http)).to_not be_nil
      end

      context 'no options are set' do
        it 'sets a default retries' do
          retries = subject.instance_variable_get(:@retries)
          expect(retries).to eq(described_class::RETRIES)
        end

        it 'sets a default backoff policy' do
          backoff_policy = subject.instance_variable_get(:@backoff_policy)
          expect(backoff_policy).to be_a(Sumologic::Metrics::BackoffPolicy)
        end
      end

      context 'options are given' do
        let(:retries) { 1234 }
        let(:backoff_policy) { FakeBackoffPolicy.new([1, 2, 3]) }
        let(:options) do
          {
            uri: uri,
            retries: retries,
            backoff_policy: backoff_policy
          }
        end

        subject { described_class.new(options) }

        it 'sets passed in retries' do
          expect(subject.instance_variable_get(:@retries)).to eq(retries)
        end

        it 'sets passed in backoff backoff policy' do
          expect(subject.instance_variable_get(:@backoff_policy))
            .to eq(backoff_policy)
        end

        it 'sets passed in path from uri' do
          path = subject.instance_variable_get(:@path)
          expect(path).to eq('/receiver/v1/http/fake_code')
        end

        it 'initializes a new Net::HTTP with passed in host and port from uri' do
          expect(Net::HTTP).to receive(:new).with('fakehost', 443)
          described_class.new(options)
        end

        it 'uses ssl when connection is https' do
          expect(Net::HTTP).to receive(:new).with('fakehost', 443)
          expect(net_http).to receive(:use_ssl=).with(true)
          described_class.new(options)
        end
      end
    end

    describe '#post' do
      let(:response) do
        Net::HTTPResponse.new(http_version, status_code, message)
      end
      let(:http_version) { 1.1 }
      let(:status_code) { 200 }
      let(:message) { 'OK' }
      let(:response_body) { '' }
      let(:batch) { [] }

      before do
        http = instance_double(Net::HTTP).as_null_object
        expect(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:request).and_return(response)
        allow(response).to receive(:body).and_return(response_body)
      end

      it 'initalizes a new Net::HTTP::Post with path and default headers' do
        path = subject.instance_variable_get(:@path)
        default_headers = {
          'Content-Type' => 'application/vnd.sumologic.carbon2',
          'User-Agent' => "sumologic-metrics/#{Metrics::VERSION}"
        }
        expect(Net::HTTP::Post).to receive(:new).with(
          path, default_headers
        ).and_call_original

        subject.post(batch)
      end

      context 'with a stub' do
        before do
          allow(described_class).to receive(:stub).and_return(true)
        end

        it 'returns a 200 response' do
          expect(subject.post(batch).status).to eq(200)
        end

        it 'has an OK message' do
          expect(subject.post(batch).message).to eq('OK')
        end

        it 'logs a debug statement' do
          expect(subject.logger).to receive(:debug).with(/stubbed request to/)
          subject.post(batch)
        end
      end

      context 'a real request' do
        RSpec.shared_examples('retried request') do |status_code, body|
          let(:status_code) { status_code }
          let(:body) { body }
          let(:retries) { 4 }
          let(:backoff_policy) { FakeBackoffPolicy.new([1000, 1000, 1000]) }
          subject do
            described_class.new(uri: uri,
                                retries: retries,
                                backoff_policy: backoff_policy)
          end

          it 'retries the request' do
            expect(subject)
              .to receive(:sleep)
              .exactly(retries - 1).times
              .with(1)
              .and_return(nil)
            subject.post(batch)
          end
        end

        RSpec.shared_examples('non-retried request') do |status_code, body|
          let(:status_code) { status_code }
          let(:body) { body }
          let(:retries) { 4 }
          let(:backoff) { 1 }
          subject { described_class.new(uri: uri, retries: retries, backoff: backoff) }

          it 'does not retry the request' do
            expect(subject)
              .to receive(:sleep)
              .never
            subject.post(batch)
          end
        end

        context 'request is successful' do
          let(:status_code) { 201 }
          it 'returns a response code' do
            expect(subject.post(batch).status).to eq(status_code)
          end

          it 'returns an OK message' do
            expect(subject.post(batch).message).to eq('OK')
          end
        end

        context 'request results in errorful response' do
          let(:status_code) { 400 }
          let(:error) { 'this is an error' }
          let(:message) { 'Invalid metric format at line 1:' }
          let(:response_body) { '' }

          it 'returns the parsed error' do
            expect(subject.post(batch).message).to eq(message)
          end
        end

        context 'a request returns a failure status code' do
          # Server errors must be retried
          it_behaves_like('retried request', 500, '{}')
          it_behaves_like('retried request', 503, '{}')

          # All 4xx errors other than 429 (rate limited) must be retried
          it_behaves_like('retried request', 429, '{}')
          it_behaves_like('non-retried request', 404, '{}')
          it_behaves_like('non-retried request', 400, '{}')
        end
      end
    end
  end
end; end
