# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountGroupsWithAssignedSecurityPolicyProjectMetric do
  before_all do
    create(:security_orchestration_policy_configuration, created_at: 2.months.ago)
    create(:security_orchestration_policy_configuration, :namespace, created_at: 2.months.ago)

    create(:security_orchestration_policy_configuration, created_at: 25.days.ago)
    create(:security_orchestration_policy_configuration, :namespace, created_at: 25.days.ago)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "security_orchestration_policy_configurations"."namespace_id") ' \
        'FROM "security_orchestration_policy_configurations"'
    end
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"security_orchestration_policy_configurations\".\"namespace_id\") " \
        "FROM \"security_orchestration_policy_configurations\" " \
        "WHERE \"security_orchestration_policy_configurations\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
