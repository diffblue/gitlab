# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueFirstAssignedAt < FirstAssignedAt
          override :name
          def self.name
            s_("CycleAnalyticsEvent|Issue first assigned")
          end

          override :identifier
          def self.identifier
            :issue_first_assigned_at
          end

          override :object_type
          def object_type
            Issue
          end

          def event_model
            ::ResourceEvents::IssueAssignmentEvent
          end
        end
      end
    end
  end
end
