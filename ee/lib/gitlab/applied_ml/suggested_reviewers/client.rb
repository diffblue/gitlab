# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module SuggestedReviewers
      class Client
        include Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb
        include Gitlab::AppliedMl::SuggestedReviewers::RecommenderServicesPb

        DEFAULT_TIMEOUT = 15
        DEFAULT_CERTS = ::Gitlab::X509::Certificate.ca_certs_bundle

        JWT_ISSUER = "gitlab-issuer"
        JWT_AUDIENCE = "gitlab-suggested-reviewers"
        SECRET_NAME = "SUGGESTED_REVIEWERS_SECRET"
        SECRET_LENGTH = 64

        NETWORK_ERRORS = [
          GRPC::DeadlineExceeded,
          GRPC::Unavailable
        ].freeze

        def self.default_rpc_url
          if Gitlab.dev_or_test_env?
            'suggested-reviewer.dev:443'
          else
            'api.unreview.io:443'
          end
        end

        def initialize(rpc_url: self.class.default_rpc_url, certs: DEFAULT_CERTS)
          raise Errors::ConfigurationError, "gRPC host unknown" if rpc_url.blank?

          @rpc_url = rpc_url
          @certs = certs
          @secret = read_secret!
        end

        def suggested_reviewers(merge_request_iid:, project_id:, changes:, author_username:, top_n: 5)
          raise Errors::ArgumentError, "Changes empty" if changes.blank?

          model_input = {
            merge_request_iid: merge_request_iid,
            top_n: top_n,
            project_id: project_id,
            changes: changes,
            author_username: author_username
          }
          response = get_reviewers(model_input)

          {
            version: response.version,
            top_n: response.top_n,
            reviewers: response.reviewers
          }
        rescue *NETWORK_ERRORS => e
          raise Errors::ConnectionFailed, e
        rescue GRPC::BadStatus => e
          raise Errors::ResourceNotAvailable, e
        end

        def register_project(project_id:, project_name:, project_namespace:, access_token:)
          registration_input = {
            project_id: project_id,
            project_name: project_name,
            project_namespace: project_namespace,
            access_token: access_token
          }
          response = send_register_project(registration_input)

          {
            project_id: response.project_id,
            registered_at: response.registered_at
          }
        rescue GRPC::AlreadyExists => e
          raise Errors::ProjectAlreadyExists, e
        rescue GRPC::BadStatus => e
          raise Errors::ResourceNotAvailable, e
        end

        def deregister_project(project_id:)
          deregistration_input = {
            project_id: project_id
          }
          response = send_deregister_project(deregistration_input)

          {
            project_id: response.project_id,
            deregistered_at: response.deregistered_at
          }
        rescue GRPC::NotFound => e
          raise Errors::ProjectNotFound, e
        rescue GRPC::BadStatus => e
          raise Errors::ResourceNotAvailable, e
        end

        private

        attr_reader :rpc_url, :certs, :secret

        def read_secret!
          secret = ENV[SECRET_NAME]

          raise Errors::ConfigurationError, "Variable #{SECRET_NAME} is missing" if secret.blank?

          if secret.length != SECRET_LENGTH
            raise Errors::ConfigurationError, "Secret must contain #{SECRET_LENGTH} bytes"
          end

          secret
        end

        def get_reviewers(model_input)
          request = MergeRequestRecommendationsReqV2.new(model_input)
          client = Stub.new(rpc_url, credentials, timeout: DEFAULT_TIMEOUT)
          client.merge_request_recommendations_v2(request)
        end

        def send_register_project(registration_input)
          request = RegisterProjectReq.new(registration_input)
          client = Stub.new(rpc_url, credentials, timeout: DEFAULT_TIMEOUT)
          client.register_project(request)
        end

        def send_deregister_project(deregistration_input)
          request = DeregisterProjectReq.new(deregistration_input)
          client = Stub.new(rpc_url, credentials, timeout: DEFAULT_TIMEOUT)
          client.deregister_project(request)
        end

        def credentials
          ssl_creds = GRPC::Core::ChannelCredentials.new(certs)

          auth_header = { "authorization": "Bearer #{token}" }
          auth_proc = proc { auth_header }
          call_creds = GRPC::Core::CallCredentials.new(auth_proc)

          ssl_creds.compose(call_creds)
        end

        def token
          JSONWebToken::HMACToken.new(secret).tap do |token|
            token.issuer = JWT_ISSUER
            token.audience = JWT_AUDIENCE
          end.encoded
        end
      end
    end
  end
end
