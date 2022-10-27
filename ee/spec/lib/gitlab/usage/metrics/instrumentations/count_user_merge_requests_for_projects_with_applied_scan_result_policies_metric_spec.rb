# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUserMergeRequestsForProjectsWithAppliedScanResultPoliciesMetric do # rubocop:disable Layout/LineLength
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }

  let_it_be(:project_with_security_policy_project) { create(:project) }
  let_it_be(:project_without_security_policy_project) { create(:project) }

  let_it_be(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project_with_security_policy_project)
  end

  let_it_be(:old_merge_request_with_security_policy_project) do
    create(:merge_request,
      source_branch: 'old-branch-1',
      target_project: project_with_security_policy_project,
      source_project: project_with_security_policy_project,
      created_at: 2.months.ago,
      author: user_1)
  end

  let_it_be(:old_merge_request_without_security_policy_project) do
    create(:merge_request,
      source_branch: 'old-branch-2',
      target_project: project_without_security_policy_project,
      source_project: project_without_security_policy_project,
      created_at: 2.months.ago,
      author: user_1)
  end

  let_it_be(:merge_request_with_security_policy_project) do
    create(:merge_request,
      source_branch: 'new-branch-1',
      target_project: project_with_security_policy_project,
      source_project: project_with_security_policy_project,
      created_at: 25.days.ago,
      author: user_2)
  end

  let_it_be(:merge_request_without_security_policy_project) do
    create(:merge_request,
      source_branch: 'new-branch-2',
      target_project: project_without_security_policy_project,
      source_project: project_without_security_policy_project,
      created_at: 25.days.ago,
      author: user_2)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "merge_requests"."author_id") FROM "merge_requests" ' \
        'INNER JOIN security_orchestration_policy_configurations ' \
        'ON merge_requests.target_project_id = security_orchestration_policy_configurations.project_id'
    end
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"merge_requests\".\"author_id\") FROM \"merge_requests\" " \
        "INNER JOIN security_orchestration_policy_configurations " \
        "ON " \
        "merge_requests.target_project_id = security_orchestration_policy_configurations.project_id " \
        "WHERE \"merge_requests\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
