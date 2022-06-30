# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ProtectedEnvironmentsRequiredApprovalsAverageMetric do
  let_it_be(:environment_with_no_approvals_required) { create(:protected_environment, created_at: 3.days.ago) }
  let_it_be(:environment_with_approvals_not_within_timeframe) { create(:protected_environment, created_at: 1.day.ago) }

  let_it_be(:environments_with_approvals_within_timeframe) do
    create(:protected_environment, :production, required_approval_count: 2, created_at: 3.days.ago)
    create(:protected_environment, :staging, required_approval_count: 1, created_at: 3.days.ago)
  end

  let(:start) { 30.days.ago.to_s(:db) }
  let(:finish) { 2.days.ago.to_s(:db) }

  let(:expected_value) { 1.5 }
  let(:expected_query) do
    "SELECT AVG(\"protected_environments\".\"required_approval_count\") FROM \"protected_environments\"" \
    " WHERE \"protected_environments\".\"required_approval_count\" >= 1" \
    " AND \"protected_environments\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
  end

  it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
end
