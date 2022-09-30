# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateApprovalMergeRequestRulesWithSecurityOrchestration do
  describe '#perform' do
    let(:batch_table) { :approval_merge_request_rules }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:approval_project_rules) { table(:approval_project_rules) }
    let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }
    let(:approval_merge_request_rules) { table(:approval_merge_request_rules) }
    let(:approval_merge_request_rule_sources) { table(:approval_merge_request_rule_sources) }
    let(:namespace) { namespaces.create!(name: 'name', path: 'path') }
    let(:project) do
      projects
        .create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
    end

    let(:namespace_2) { namespaces.create!(name: 'name_2', path: 'path_2') }
    let(:security_project) do
      projects
        .create!(name: "security_project", path: "security_project", namespace_id: namespace_2.id,
                 project_namespace_id: namespace_2.id)
    end

    let!(:security_orchestration_policy_configuration) do
      security_orchestration_policy_configurations
        .create!(project_id: project.id, security_policy_management_project_id: security_project.id)
    end

    let!(:project_rule) do
      approval_project_rules.create!(name: 'rule', project_id: project.id, report_type: 4)
    end

    let!(:project_rule_unrelated) do
      approval_project_rules.create!(name: 'rule 3', project_id: security_project.id, report_type: 4)
    end

    let(:merge_request) do
      table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'feature')
    end

    let!(:merge_request_rule) do
      approval_merge_request_rules.create!(name: 'rule', merge_request_id: merge_request.id, report_type: 4)
    end

    let!(:merge_request_rule_other_report_type) do
      approval_merge_request_rules.create!(name: 'rule 2', merge_request_id: merge_request.id, report_type: 1)
    end

    let!(:merge_request_rule_last) do
      approval_merge_request_rules.create!(name: 'rule 3', merge_request_id: merge_request.id, report_type: 4)
    end

    let!(:approval_merge_request_rule_source) do
      approval_merge_request_rule_sources.create!(approval_merge_request_rule_id: merge_request_rule.id,
                                                  approval_project_rule_id: project_rule.id)
    end

    let!(:approval_merge_request_rule_source_other_report_type) do
      approval_merge_request_rule_sources
        .create!(approval_merge_request_rule_id: merge_request_rule_other_report_type.id,
                 approval_project_rule_id: project_rule.id)
    end

    let!(:approval_merge_request_rule_source_last) do
      approval_merge_request_rule_sources.create!(approval_merge_request_rule_id: merge_request_rule_last.id,
                                                  approval_project_rule_id: project_rule_unrelated.id)
    end

    subject do
      described_class.new(
        start_id: merge_request_rule.id,
        end_id: merge_request_rule_last.id,
        batch_table: batch_table,
        batch_column: batch_column,
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        connection: connection
      ).perform
    end

    it 'updates only approval rules with projects linked to a security project and report_type equals to 4' do
      subject

      expect(merge_request_rule.reload.security_orchestration_policy_configuration_id)
        .to eq(security_orchestration_policy_configuration.id)
      expect(merge_request_rule_other_report_type.reload.security_orchestration_policy_configuration_id).to be_nil
      expect(merge_request_rule_last.reload.security_orchestration_policy_configuration_id).to be_nil
    end
  end
end
