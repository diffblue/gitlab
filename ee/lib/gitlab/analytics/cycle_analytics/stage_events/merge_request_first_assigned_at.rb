# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestFirstAssignedAt < FirstAssignedAt
          override :name
          def self.name
            s_("CycleAnalyticsEvent|Merge request first assigned")
          end

          override :identifier
          def self.identifier
            :merge_request_first_assigned_at
          end

          override :object_type
          def object_type
            MergeRequest
          end

          def event_model
            ::ResourceEvents::MergeRequestAssignmentEvent
          end
        end
      end
    end
  end
end
