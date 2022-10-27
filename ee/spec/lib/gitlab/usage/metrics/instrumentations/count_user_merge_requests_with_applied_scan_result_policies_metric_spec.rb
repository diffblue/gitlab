# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUserMergeRequestsWithAppliedScanResultPoliciesMetric do
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }

  let_it_be(:old_merge_request) { create(:merge_request, created_at: 2.months.ago, author: user_1) }
  let_it_be(:merge_request) { create(:merge_request, created_at: 25.days.ago, author: user_2) }
  let_it_be(:other_merge_request) { create(:merge_request, created_at: 25.days.ago, author: user_2) }

  let_it_be(:old_scan_finding_approval_merge_request_rule) do
    create(:report_approver_rule, :scan_finding, merge_request: old_merge_request)
  end

  let_it_be(:old_code_coverage_approval_merge_request_rule) do
    create(:report_approver_rule, :code_coverage, merge_request: old_merge_request)
  end

  let_it_be(:scan_finding_approval_merge_request_rule) do
    create(:report_approver_rule, :scan_finding, merge_request: merge_request)
  end

  let_it_be(:code_coverage_approval_merge_request_rule) do
    create(:report_approver_rule, :code_coverage, merge_request: merge_request)
  end

  let_it_be(:other_scan_finding_approval_merge_request_rule) do
    create(:report_approver_rule, :scan_finding, merge_request: other_merge_request)
  end

  let_it_be(:other_code_coverage_approval_merge_request_rule) do
    create(:report_approver_rule, :code_coverage, merge_request: other_merge_request)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "merge_requests"."author_id") FROM "merge_requests" ' \
        'INNER JOIN "approval_merge_request_rules" ' \
        'ON "approval_merge_request_rules"."merge_request_id" = "merge_requests"."id" ' \
        'WHERE "approval_merge_request_rules"."report_type" = 4'
    end
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"merge_requests\".\"author_id\") FROM \"merge_requests\" " \
        "INNER JOIN \"approval_merge_request_rules\" " \
        "ON \"approval_merge_request_rules\".\"merge_request_id\" = \"merge_requests\".\"id\" " \
        "WHERE \"approval_merge_request_rules\".\"report_type\" = 4 AND " \
        "\"merge_requests\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
