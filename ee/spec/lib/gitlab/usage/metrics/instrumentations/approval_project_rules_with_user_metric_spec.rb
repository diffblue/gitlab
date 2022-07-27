# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ApprovalProjectRulesWithUserMetric do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    allow(ApprovalProjectRule.connection).to receive(:transaction_open?).and_return(false)
  end

  let(:expected_value) { 2 }
  let(:expected_query) do
    "SELECT COUNT(*) FROM (SELECT COUNT(\"approval_project_rules\".\"id\") FROM \"approval_project_rules\" INNER JOIN approval_project_rules_users ON approval_project_rules_users.approval_project_rule_id = approval_project_rules.id WHERE \"approval_project_rules\".\"rule_type\" = 0 GROUP BY \"approval_project_rules\".\"id\" HAVING (#{having_clause})) subquery"
  end

  context 'for more approvers than required' do
    let(:having_clause) { 'COUNT(approval_project_rules_users) > approvals_required' }

    before do
      create_list(:approval_project_rule, 2, project: project, users: create_list(:user, 2), approvals_required: 1)
    end

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', options: { count_type: 'more_approvers_than_required' } }
  end

  context 'for more approvers than required' do
    let(:having_clause) { 'COUNT(approval_project_rules_users) < approvals_required' }

    before do
      create_list(:approval_project_rule, 2, project: project, users: [user], approvals_required: 2)
    end

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', options: { count_type: 'less_approvers_than_required' } }
  end

  context 'for more approvers than required' do
    let(:having_clause) { "COUNT(approval_project_rules_users) = approvals_required" }

    before do
      create_list(:approval_project_rule, 2, project: project, users: [user], approvals_required: 1)
    end

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', options: { count_type: 'exact_required_approvers' } }
  end
end
