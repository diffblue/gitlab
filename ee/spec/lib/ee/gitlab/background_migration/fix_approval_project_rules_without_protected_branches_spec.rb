# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixApprovalProjectRulesWithoutProtectedBranches,
feature_category: :security_policy_management do
  describe '#perform' do
    let(:batch_table) { :approval_project_rules }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:approval_project_rules) { table(:approval_project_rules) }
    let(:protected_branches) { table(:protected_branches) }
    let(:approval_project_rules_protected_branches) { table(:approval_project_rules_protected_branches) }
    let(:namespace) { namespaces.create!(name: 'name', path: 'path') }
    let(:project) do
      projects
        .create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
    end

    let!(:protected_branch) do
      protected_branches.create!(name: 'main', project_id: project.id)
    end

    let!(:project_rule) do
      approval_project_rules.create!(name: 'rule', project_id: project.id, report_type: 4)
    end

    let!(:project_rule_with_protected_branches) do
      approval_project_rules.create!(name: 'rule', project_id: project.id, report_type: 4)
    end

    let!(:approval_project_rules_protected_branch) do
      approval_project_rules_protected_branches.create!(
        approval_project_rule_id: project_rule_with_protected_branches.id, protected_branch_id: protected_branch.id)
    end

    let!(:project_rule_other_report_type) do
      approval_project_rules.create!(name: 'rule 2', project_id: project.id, report_type: 1)
    end

    let!(:project_rule_last) do
      approval_project_rules.create!(name: 'rule 3', project_id: project.id, report_type: 4,
                                     applies_to_all_protected_branches: true)
    end

    let(:migration) do
      described_class.new(
        start_id: project_rule.id,
        end_id: project_rule_last.id,
        batch_table: batch_table,
        batch_column: batch_column,
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        connection: connection
      )
    end

    subject { migration.perform }

    it 'updates only approval rules without protected branches and report_type equals to 4' do
      expect { subject }
        .to change { project_rule.reload.applies_to_all_protected_branches }.to(true)
        .and not_change { project_rule_last.reload.applies_to_all_protected_branches }
        .and not_change { project_rule_with_protected_branches.reload.applies_to_all_protected_branches }
        .and not_change { project_rule_other_report_type.reload.applies_to_all_protected_branches }
    end

    it 'filters approval rules from scope' do
      expected = approval_project_rules.where(report_type: 4, applies_to_all_protected_branches: false)
      actual = migration.filter_batch(approval_project_rules)

      expect(actual).to match_array(expected)
    end
  end
end
