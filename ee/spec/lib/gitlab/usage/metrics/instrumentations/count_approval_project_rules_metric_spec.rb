# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountApprovalProjectRulesMetric,
feature_category: :compliance_management do
  let_it_be(:approval_project_rules) { create_list(:approval_project_rule, 2, created_at: 4.days.ago) }
  let_it_be(:old_approval_project_rule) { create_list(:approval_project_rule, 2, created_at: 2.months.ago) }

  context 'with all time frame' do
    let(:expected_value) { 4 }
    let(:expected_query) { 'SELECT COUNT("approval_project_rules"."id") FROM "approval_project_rules"' }

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
  end
end
