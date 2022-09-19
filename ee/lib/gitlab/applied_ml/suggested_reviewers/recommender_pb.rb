# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module SuggestedReviewers
      module RecommenderPb
        Google::Protobuf::DescriptorPool.generated_pool.build do
          add_file("bot/recommender.proto", syntax: :proto3) do
            add_message "bot.MergeRequestRecommendationsReqV2" do
              optional :merge_request_iid, :int64, 1
              optional :top_n, :int32, 2
              optional :project_id, :int64, 3
              repeated :changes, :string, 4
              optional :author_username, :string, 5
            end
            add_message "bot.MergeRequestRecommendationsResV2" do
              optional :version, :string, 1
              optional :top_n, :int32, 2
              repeated :reviewers, :string, 3
            end
          end
        rescue Google::Protobuf::TypeError
          'Log'
        end

        # rubocop: disable Layout/LineLength
        MergeRequestRecommendationsReqV2 = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.MergeRequestRecommendationsReqV2").msgclass
        MergeRequestRecommendationsResV2 = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.MergeRequestRecommendationsResV2").msgclass
        # rubocop: enable Layout/LineLength
      end
    end
  end
end
