# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module SuggestedReviewers
      class Client
        include Gitlab::AppliedMl::SuggestedReviewers::RecommenderPb
        include Gitlab::AppliedMl::SuggestedReviewers::RecommenderServicesPb

        DEFAULT_TIMEOUT = 15

        attr_reader :rpc_url

        def initialize(rpc_url: '')
          @rpc_url = rpc_url
        end

        def suggested_reviewers(merge_request_iid:, project_id:, changes:, author_username:, top_n: 5)
          raise Gitlab::AppliedMl::Errors::ArgumentError, "Changes empty" if changes.blank?
          raise Gitlab::AppliedMl::Errors::ConfigurationError, "gRPC host unknown" if rpc_url.blank?

          model_input = {
            mergeRequestIid: merge_request_iid,
            topN: top_n,
            projectId: project_id,
            changes: changes,
            authorUsername: author_username
          }
          response = get_reviewers(model_input)

          {
            version: response.version,
            top_n: response.topN,
            reviewers: response.reviewers
          }
        rescue GRPC::BadStatus => e
          raise Gitlab::AppliedMl::Errors::ResourceNotAvailable, e
        end

        private

        def get_reviewers(model_input)
          request = MergeRequestRecommendationsReqV2.new(model_input)
          # TODO: Authentication between GitLab and the suggested reviewers service is coming in
          # https://gitlab.com/gitlab-org/modelops/applied-ml/review-recommender/recommender-bot-service/-/issues/19
          client = Stub.new(rpc_url, :this_channel_is_insecure, timeout: DEFAULT_TIMEOUT)
          client.merge_request_recommendations_v2(request)
        end
      end
    end
  end
end
