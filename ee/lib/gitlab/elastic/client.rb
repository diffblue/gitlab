# frozen_string_literal: true

require 'faraday_middleware/aws_sigv4'

module Gitlab
  module Elastic
    module Client
      extend Gitlab::Utils::StrongMemoize

      OPEN_TIMEOUT = 5
      NO_RETRY = 0

      # Takes a hash as returned by `ApplicationSetting#elasticsearch_config`,
      # and configures itself based on those parameters
      def self.build(config)
        base_config = {
          adapter: self.adapter,
          urls: config[:url],
          transport_options: {
            request: {
              timeout: config[:client_request_timeout],
              open_timeout: OPEN_TIMEOUT
            }
          },
          randomize_hosts: true,
          retry_on_failure: config[:retry_on_failure] || NO_RETRY,
          log: debug?,
          debug: debug?
        }.compact

        if config[:aws]
          creds = resolve_aws_credentials(config)
          region = config[:aws_region]

          ::Elasticsearch::Client.new(base_config) do |fmid|
            fmid.request(:aws_sigv4, credentials_provider: creds, service: 'es', region: region)
          end
        else
          ::Elasticsearch::Client.new(base_config)
        end
      end

      def self.adapter
        ::Feature.enabled?(:use_typhoeus_elasticsearch_adapter) ? :typhoeus : :net_http
      end

      def self.debug?
        Gitlab.dev_or_test_env? && Gitlab::Utils.to_boolean(ENV['ELASTIC_CLIENT_DEBUG'])
      end

      def self.resolve_aws_credentials(config)
        # Resolve credentials in order
        # 1.  Static config
        # 2.  ec2 instance profile
        static_credentials = Aws::Credentials.new(config[:aws_access_key], config[:aws_secret_access_key])

        return static_credentials if static_credentials&.set?

        # When static credentials are not configured, use Aws::CredentialProviderChain API
        aws_credential_provider if aws_credential_provider&.set?
      end

      def self.aws_credential_provider
        # Aws::CredentialProviderChain API will check AWS access credential environment
        # variables, AWS credential profile, ECS credential service and EC2 credential service.
        # Please see aws-sdk-core/lib/aws-sdk-core/credential_provider_chain.rb for details of
        # the possible providers and order of the providers.
        strong_memoize(:instance_credentials) do
          Aws::CredentialProviderChain.new.resolve
        end
      end
    end
  end
end
