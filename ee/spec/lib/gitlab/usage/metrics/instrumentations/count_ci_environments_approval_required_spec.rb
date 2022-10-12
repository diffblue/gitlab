# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiEnvironmentsApprovalRequired do
  context 'for all time frame' do
    let_it_be(:protected_environment_approval_rules) do
      create_list(:protected_environment_approval_rule, 2, :maintainer_access)
    end

    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "protected_environment_approval_rules"."protected_environment_id")' \
        ' FROM "protected_environment_approval_rules"'
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all'
  end

  context 'with multiple approvals per environment' do
    let_it_be(:protected_environment) { create(:protected_environment) }
    let_it_be(:protected_environment_approval_rules) do
      create_list(:protected_environment_approval_rule, 2,
                  :maintainer_access, protected_environment: protected_environment)
    end

    let(:expected_value) { 1 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "protected_environment_approval_rules"."protected_environment_id")' \
        ' FROM "protected_environment_approval_rules"'
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all'
  end

  context 'for 28d time frame' do
    let_it_be(:old_protected_environment_approval_rules) do
      create_list(:protected_environment_approval_rule, 2, :maintainer_access, created_at: 31.days.ago)
    end

    let_it_be(:protected_environment_approval_rules) do
      create_list(:protected_environment_approval_rule, 2, :maintainer_access, created_at: 3.days.ago)
    end

    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }

    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "protected_environment_approval_rules"."protected_environment_id")' \
        ' FROM "protected_environment_approval_rules" WHERE' \
        " \"protected_environment_approval_rules\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
  end
end
