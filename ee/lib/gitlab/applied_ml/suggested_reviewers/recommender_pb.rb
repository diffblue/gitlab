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
            add_message "bot.RegisterProjectReq" do
              optional :project_id, :int64, 1
              optional :project_name, :string, 2
              optional :project_namespace, :string, 3
              optional :access_token, :string, 4
            end
            add_message "bot.RegisterProjectRes" do
              optional :project_id, :int64, 1
              optional :registered_at, :string, 2
            end
            add_message "bot.DeregisterProjectReq" do
              optional :project_id, :int64, 1
            end
            add_message "bot.DeregisterProjectRes" do
              optional :project_id, :int64, 1
              optional :deregistered_at, :string, 2
            end
          end
        rescue Google::Protobuf::TypeError
          'Log'
        end

        # rubocop: disable Layout/LineLength
        MergeRequestRecommendationsReqV2 = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.MergeRequestRecommendationsReqV2").msgclass
        MergeRequestRecommendationsResV2 = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.MergeRequestRecommendationsResV2").msgclass
        RegisterProjectReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.RegisterProjectReq").msgclass
        RegisterProjectRes = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.RegisterProjectRes").msgclass
        DeregisterProjectReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.DeregisterProjectReq").msgclass
        DeregisterProjectRes = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("bot.DeregisterProjectRes").msgclass
        # rubocop: enable Layout/LineLength
      end
    end
  end
end
