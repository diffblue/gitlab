# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::Client do
  describe '.build' do
    let(:client) { described_class.build(params) }

    context 'without credentials' do
      let(:params) { { url: 'http://dummy-elastic:9200' } }

      it 'makes unsigned requests' do
        stub_request(:get, 'http://dummy-elastic:9200/foo/_doc/1')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: [:fake_response])

        expect(client.get(index: 'foo', id: 1)).to eq([:fake_response])
      end

      it 'does not set request timeout in transport' do
        options = client.transport.options.dig(:transport_options, :request)

        expect(options).to include(open_timeout: described_class::OPEN_TIMEOUT, timeout: nil)
      end

      it 'does not set log & debug flags by default' do
        expect(client.transport.options).not_to include(debug: true, log: true)
      end

      it 'sets log & debug flags if .debug? is true' do
        allow(described_class).to receive(:debug?).and_return(true)

        expect(client.transport.options).to include(debug: true, log: true)
      end

      context 'with typhoeus adapter for keep-alive connections' do
        it 'sets typhoeus as the adapter' do
          options = client.transport.options

          expect(options).to include(adapter: :typhoeus)
        end

        context 'when use_typhoeus_elasticsearch_adapter FeatureFlag is disabled' do
          before do
            stub_feature_flags(use_typhoeus_elasticsearch_adapter: false)
          end

          it 'uses the net/http adapter' do
            options = client.transport.options
            expect(options).to include(adapter: :net_http)
          end
        end

        context 'cached client when FeatureFlag changes' do
          it 'successfully changes adapter from net/http to typhoeus' do
            stub_feature_flags(use_typhoeus_elasticsearch_adapter: false)
            adapter = Issue.__elasticsearch__.client.transport.connections.first.connection.builder.adapter
            expect(adapter).to eq(::Faraday::Adapter::NetHttp)

            stub_feature_flags(use_typhoeus_elasticsearch_adapter: true)
            adapter = Issue.__elasticsearch__.client.transport.connections.first.connection.builder.adapter
            expect(adapter).to eq(::Faraday::Adapter::Typhoeus)
          end
        end
      end

      context 'with client_request_timeout in config' do
        let(:params) { { url: 'http://dummy-elastic:9200', client_request_timeout: 30 } }

        it 'sets request timeout in transport' do
          options = client.transport.options.dig(:transport_options, :request)

          expect(options).to include(open_timeout: described_class::OPEN_TIMEOUT, timeout: 30)
        end
      end

      context 'with retry_on_failure' do
        using RSpec::Parameterized::TableSyntax

        where(:retry_on_failure, :client_retry) do
          nil   | 0    # not set or nil, no retry
          false | 0    # with false, no retry
          true  | true # with true, retry with default times
          10    | 10   # with a number N, retry N times
        end

        with_them do
          let(:params) { { url: 'http://dummy-elastic:9200', retry_on_failure: retry_on_failure } }

          it 'sets retry in transport' do
            expect(client.transport.options.dig(:retry_on_failure)).to eq(client_retry)
          end
        end
      end
    end

    context 'with AWS IAM static credentials' do
      let(:params) do
        {
          url: 'http://example-elastic:9200',
          aws: true,
          aws_region: 'us-east-1',
          aws_access_key: '0',
          aws_secret_access_key: '0'
        }
      end

      it 'signs_requests' do
        # Mock the correlation ID (passed as header) to have deterministic signature
        allow(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return('new-correlation-id')

        travel_to(Time.parse('20170303T133952Z')) do
          stub_request(:get, 'http://example-elastic:9200/foo/_doc/1')
            .with(
              headers: {
                'Authorization' => /^AWS4-HMAC-SHA256 Credential=0/,
                'Content-Type' => 'application/json',
                'Expect' => '',
                'Host' => 'example-elastic:9200',
                'User-Agent' => /^elasticsearch-ruby/,
                'X-Amz-Content-Sha256' => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                'X-Amz-Date' => '20170303T133952Z',
                'X-Elastic-Client-Meta' => "es=7.13.3,rb=#{RUBY_VERSION},t=7.13.3,fd=1.10.0,ty=1.4.0",
                'X-Opaque-Id' => 'new-correlation-id'
              }
            ).to_return(status: 200, body: [:fake_response])

          expect(client.get(index: 'foo', id: 1)).to eq([:fake_response])
        end
      end
    end
  end

  describe '.resolve_aws_credentials' do
    let(:creds) { described_class.resolve_aws_credentials(params) }

    context 'when the AWS IAM static credentials are valid' do
      let(:params) do
        {
          url: 'http://example-elastic:9200',
          aws: true,
          aws_region: 'us-east-1',
          aws_access_key: '0',
          aws_secret_access_key: '0'
        }
      end

      it 'returns credentials from static credentials without making an HTTP request' do
        expect(creds.credentials.access_key_id).to eq '0'
        expect(creds.credentials.secret_access_key).to eq '0'
      end
    end

    context 'when the AWS IAM static credentials are invalid' do
      let(:params) do
        {
          url: 'http://example-elastic:9200',
          aws: true,
          aws_region: 'us-east-1'
        }
      end

      before do
        allow_next_instance_of(Aws::CredentialProviderChain) do |instance|
          allow(instance).to receive(:resolve).and_return(credentials)
        end
      end

      after do
        described_class.clear_memoization(:instance_credentials)
      end

      context 'when aws sdk provides credentials' do
        let(:credentials) { double(:aws_credentials, set?: true) }

        it 'return the credentials' do
          expect(creds).to eq(credentials)
        end
      end

      context 'when aws sdk does not provide credentials' do
        let(:credentials) { nil }

        it 'return the credentials' do
          expect(creds).to eq(nil)
        end
      end

      context 'when Aws::CredentialProviderChain returns unset credentials' do
        let(:credentials) { double(:aws_credentials, set?: false) }

        it 'returns nil' do
          expect(creds).to eq(nil)
        end
      end
    end
  end

  describe '.aws_credential_provider' do
    let(:creds) { described_class.aws_credential_provider }

    before do
      allow_next_instance_of(Aws::CredentialProviderChain) do |instance|
        allow(instance).to receive(:resolve).and_return(credentials)
      end
    end

    after do
      described_class.clear_memoization(:instance_credentials)
    end

    context 'when Aws::CredentialProviderChain returns set credentials' do
      let(:credentials) { double(:aws_credentials) }

      it 'returns credentials' do
        expect(creds).to eq(credentials)
      end
    end

    context 'when Aws::CredentialProviderChain returns nil' do
      let(:credentials) { nil }

      it 'returns nil' do
        expect(creds).to eq(nil)
      end
    end
  end

  describe '.debug?' do
    using RSpec::Parameterized::TableSyntax

    where(:dev_or_test_env, :env_variable, :expected_result) do
      false | 'true'  | false
      false | 'false' | false
      true  | 'false' | false
      true  | 'true'  | true
    end

    with_them do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test_env)
        allow(ENV).to receive(:[]).with('ELASTIC_CLIENT_DEBUG').and_return(env_variable)
      end

      it 'returns expected result' do
        expect(described_class.debug?).to eq(expected_result)
      end
    end
  end
end
