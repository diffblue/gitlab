# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedTransferredProjectApprovalRules, schema: 20230724164745, feature_category: :security_policy_management do # rubocop:disable Layout/LineLength
  describe '#perform' do
    let(:batch_table) { :approval_project_rules }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:approval_project_rules) { table(:approval_project_rules) }
    let(:approval_merge_request_rules) { table(:approval_merge_request_rules) }
    let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }

    let(:group_1) { namespaces.create!(name: 'group 1', path: 'group-1') }
    let!(:group_2) { namespaces.create!(name: 'group 2', path: 'group-2') }
    let!(:project) do
      projects
        .create!(name: "project", path: "project", namespace_id: group_1.id, project_namespace_id: group_1.id)
    end

    let!(:security_project_1) do
      projects
        .create!(name: "security_project", path: "security_project", namespace_id: group_1.id,
          project_namespace_id: namespaces.create!(name: 'security project 1', path: 'sp-1').id)
    end

    let!(:security_project_2) do
      projects
        .create!(name: "security_project_2", path: "security_project_2", namespace_id: group_2.id,
          project_namespace_id: namespaces.create!(name: 'security project 2', path: 'sp-2').id)
    end

    let!(:project_last) do
      projects.create!(name: "project 2", path: "project-2", namespace_id: group_2.id, project_namespace_id: group_2.id)
    end

    let!(:security_orchestration_policy_configuration) do
      security_orchestration_policy_configurations
        .create!(namespace_id: group_1.id, security_policy_management_project_id: security_project_1.id)
    end

    let!(:security_orchestration_policy_configuration_2) do
      security_orchestration_policy_configurations
        .create!(namespace_id: group_2.id, security_policy_management_project_id: security_project_2.id)
    end

    let!(:project_rule_scan_finding_outdated) do
      approval_project_rules.create!(name: 'scan finding rule outdated', project_id: project.id, report_type: 4,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_2.id)
    end

    let!(:project_rule_license_scanning_outdated) do
      approval_project_rules.create!(name: 'license scanning rule outdated', project_id: project.id, report_type: 2,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_2.id)
    end

    let!(:project_rule_other_report_type_outdated) do
      approval_project_rules.create!(
        name: 'rule other type outdated',
        project_id: project.id,
        report_type: 1,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_2.id)
    end

    let!(:project_rule_without_configuration_outdated) do
      approval_project_rules.create!(
        name: 'rule without configuration outdated',
        project_id: project.id,
        report_type: 2)
    end

    let!(:project_rule_scan_finding_current) do
      approval_project_rules.create!(
        name: 'rule scan finding current',
        project_id: project.id,
        report_type: 4,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    let!(:project_rule_license_scanning_current) do
      approval_project_rules.create!(
        name: 'rule license scanning current',
        project_id: project.id,
        report_type: 2,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    subject do
      described_class.new(
        start_id: project_rule_scan_finding_outdated.id,
        end_id: project_rule_license_scanning_current.id,
        batch_table: batch_table,
        batch_column: batch_column,
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        connection: connection
      ).perform
    end

    it 'delete only outdated approval project rules where report_type equals to 4 and 2' do
      expect { subject }.to change { approval_project_rules.count }.from(6).to(4)
      expect(approval_project_rules.all).to(
        contain_exactly(project_rule_license_scanning_current, project_rule_scan_finding_current,
          project_rule_without_configuration_outdated, project_rule_other_report_type_outdated)
      )
    end

    it 'enqueues a worker to sync the affected project' do
      expect(Security::ScanResultPolicies::SyncProjectWorker).to receive(:perform_async).with(project.id)

      subject
    end
  end
end
