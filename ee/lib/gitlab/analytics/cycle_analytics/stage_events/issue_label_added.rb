# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueLabelAdded < LabelBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue label was added")
          end

          def self.identifier
            :issue_label_added
          end

          def html_description(options)
            s_("CycleAnalyticsEvent|%{label_reference} label was added to the issue") % { label_reference: options.fetch(:label_html) }
          end

          def object_type
            Issue
          end

          def subquery
            resource_label_events_with_subquery(:issue_id, label, ::ResourceLabelEvent.actions[:add], :asc)
          end
        end
      end
    end
  end
end
