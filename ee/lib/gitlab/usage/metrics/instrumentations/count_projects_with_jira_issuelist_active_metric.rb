# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithJiraIssuelistActiveMetric < DatabaseMetric
          operation :distinct_count

          start do
            ::Integrations::JiraTrackerData.where(issues_enabled: true).minimum(:integration_id)
          end

          finish do
            ::Integrations::JiraTrackerData.where(issues_enabled: true).maximum(:integration_id)
          end

          relation do
            ::Integrations::Jira
              .active
              .left_outer_joins(:jira_tracker_data)
              .where(jira_tracker_data: { issues_enabled: true })
          end
        end
      end
    end
  end
end
