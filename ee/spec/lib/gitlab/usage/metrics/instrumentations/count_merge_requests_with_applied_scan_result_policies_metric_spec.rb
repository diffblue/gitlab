# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountMergeRequestsWithAppliedScanResultPoliciesMetric do
  let_it_be(:old_scan_finding_approval_merge_request_rule) do
    create(:report_approver_rule, :scan_finding, created_at: 2.months.ago)
  end

  let_it_be(:scan_finding_approval_merge_request_rule) do
    create(:report_approver_rule, :scan_finding, created_at: 25.days.ago)
  end

  let_it_be(:code_coverage_approval_merge_request_rule) { create(:report_approver_rule, :code_coverage) }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "approval_merge_request_rules"."merge_request_id") ' \
        'FROM "approval_merge_request_rules" WHERE "approval_merge_request_rules"."report_type" = 4'
    end
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"approval_merge_request_rules\".\"merge_request_id\") " \
        "FROM \"approval_merge_request_rules\" WHERE \"approval_merge_request_rules\".\"report_type\" = 4 " \
        "AND \"approval_merge_request_rules\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
