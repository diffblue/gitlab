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

        def initialize(rpc_url: '', certs: DEFAULT_CERTS)
          @rpc_url = rpc_url
          @certs = certs
          @secret = read_secret!
        end

        def suggested_reviewers(merge_request_iid:, project_id:, changes:, author_username:, top_n: 5)
          raise Errors::ArgumentError, "Changes empty" if changes.blank?
          raise Errors::ConfigurationError, "gRPC host unknown" if rpc_url.blank?

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
        rescue GRPC::BadStatus => e
          raise Gitlab::AppliedMl::Errors::ResourceNotAvailable, e
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
