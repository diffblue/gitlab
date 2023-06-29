# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithJiraIssuelistActiveMetric,
  feature_category: :integrations do
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:jira_project_with_issuelist) do
    create(:jira_integration, project: project_1, issues_enabled: true, project_key: 'foo')
  end

  let_it_be(:jira_project_without_issuelist) do
    create(:jira_integration, project: project_2, issues_enabled: false, project_key: 'bar')
  end

  let(:expected_value) { 1 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "integrations"."id") FROM "integrations" ' \
      'LEFT OUTER JOIN "jira_tracker_data" ON "jira_tracker_data"."integration_id" = "integrations"."id" ' \
      'WHERE "integrations"."type_new" = \'Integrations::Jira\' AND "integrations"."active" = TRUE ' \
      'AND "jira_tracker_data"."issues_enabled" = TRUE'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
