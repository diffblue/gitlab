# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ProtectedEnvironmentApprovalRulesRequiredApprovalsAverageMetric do # rubocop:disable Layout/LineLength
  # rubocop:disable Layout/LineLength
  let_it_be(:rule_not_within_timeframe) { create(:protected_environment_approval_rule, :maintainer_access, created_at: 1.day.ago) }
  let_it_be(:rule_for_maintainer_within_timeframe) { create(:protected_environment_approval_rule, :maintainer_access, required_approvals: 2, created_at: 3.days.ago) }
  let_it_be(:rule_for_developer_within_timeframe) { create(:protected_environment_approval_rule, :developer_access, required_approvals: 1, created_at: 3.days.ago) }
  # rubocop:enable Layout/LineLength

  let(:start) { 30.days.ago.to_s(:db) }
  let(:finish) { 2.days.ago.to_s(:db) }

  let(:expected_value) { 1.5 }
  let(:expected_query) do
    "SELECT AVG(\"protected_environment_approval_rules\".\"required_approvals\")" \
    " FROM \"protected_environment_approval_rules\"" \
    " WHERE \"protected_environment_approval_rules\".\"required_approvals\" >= 1" \
    " AND \"protected_environment_approval_rules\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
  end

  it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
end
