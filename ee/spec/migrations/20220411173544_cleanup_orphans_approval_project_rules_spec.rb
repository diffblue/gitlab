# frozen_string_literal: true
require 'spec_helper'

require_migration!

RSpec.describe CleanupOrphansApprovalProjectRules, feature_category: :source_code_management do
  let(:approval_project_rules) { table(:approval_project_rules) }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:projects) { table(:projects) }
  let(:project) do
    projects
      .create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
  end

  let!(:scan_finding_rule) do
    approval_project_rules.create!(name: "scan result", project_id: project.id, report_type: 4, rule_type: 2)
  end

  let!(:license_scan_rule) do
    approval_project_rules.create!(name: "License-Check", project_id: project.id, report_type: 2, rule_type: 2)
  end

  it 'deletes only scan_finding rule from orphan project' do
    expect { migrate! }.to change { ApprovalProjectRule.count }.from(2).to(1)
  end

  context 'with an existing security orchestration project' do
    let(:namespace_security) { table(:namespaces).create!(name: 'name_2', path: 'path_2') }
    let(:security_project) do
      projects.create!(
        name: "security",
        path: "security",
        namespace_id: namespace_security.id,
        project_namespace_id: namespace_security.id)
    end

    let!(:policy_configuration) do
      table(:security_orchestration_policy_configurations).create!(
        project_id: project.id,
        security_policy_management_project_id: security_project.id)
    end

    it 'does not delete scan_finding rules' do
      expect { migrate! }.not_to change { ApprovalProjectRule.count }
    end
  end
end
