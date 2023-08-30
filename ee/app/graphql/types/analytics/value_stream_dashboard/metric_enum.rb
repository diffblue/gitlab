# frozen_string_literal: true

module Types
  module Analytics
    module ValueStreamDashboard
      class MetricEnum < BaseEnum
        graphql_name 'ValueStreamDashboardMetric'
        description 'Possible identifier types for a measurement'

        value 'PROJECTS', 'Project count.', value: 'projects'
        value 'ISSUES', 'Issue count.', value: 'issues'
        value 'GROUPS', 'Group count.', value: 'groups'
        value 'MERGE_REQUESTS', 'Merge request count.', value: 'merge_requests'
        value 'PIPELINES', 'Pipeline count.', value: 'pipelines'
      end
    end
  end
end
