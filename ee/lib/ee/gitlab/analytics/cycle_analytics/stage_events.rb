# frozen_string_literal: true

module EE
  module Gitlab
    module Analytics
      module CycleAnalytics
        module StageEvents
          extend ActiveSupport::Concern

          prepended do
            extend ::Gitlab::Utils::StrongMemoize
          end

          EE_ENUM_MAPPING = {
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed => 3,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAddedToBoard => 4,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssociatedWithMilestone => 5,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited => 7,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded => 8,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved => 9,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt => 11,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed => 105,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited => 106,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded => 107,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved => 108,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt => 109,
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt => 110
          }.freeze

          EE_EVENTS = EE_ENUM_MAPPING.keys.freeze

          EE_PAIRING_RULES = {
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueCreated => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAddedToBoard,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssociatedWithMilestone,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAddedToBoard => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssociatedWithMilestone,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssociatedWithMilestone => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAddedToBoard,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssociatedWithMilestone,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAddedToBoard,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssignedAt => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAddedToBoard,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstAssociatedWithMilestone,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueFirstMentionedInCommit,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::IssueLabelRemoved
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildStarted,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildFinished,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestCreated => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildStarted,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildFinished,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildStarted => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildFinished => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstCommitAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt
            ],
            ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt => [
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestClosed,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastBuildStarted,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstDeployedToProduction,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLastEdited,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelAdded,
              ::Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved
            ]
          }.freeze

          class_methods do
            extend ::Gitlab::Utils::Override

            override :events
            def events
              strong_memoize(:events) do
                (super + EE_EVENTS)
              end
            end

            override :pairing_rules
            def pairing_rules
              strong_memoize(:pairing_rules) do
                # merging two hashes with array values
                ::Gitlab::Analytics::CycleAnalytics::StageEvents::PAIRING_RULES.merge(EE_PAIRING_RULES) do |klass, foss_events, ee_events|
                  foss_events + ee_events
                end
              end
            end

            override :enum_mapping
            def enum_mapping
              strong_memoize(:enum_mapping) do
                super.merge(EE_ENUM_MAPPING)
              end
            end
          end
        end
      end
    end
  end
end
