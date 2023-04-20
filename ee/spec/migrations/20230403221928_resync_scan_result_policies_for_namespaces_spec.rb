# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ResyncScanResultPoliciesForNamespaces, feature_category: :security_policy_management do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }

  let(:group_namespace_1) do
    namespaces.create!(name: 'group_1', path: 'group_1', type: 'Group').tap do |group|
      group.update!(traversal_ids: [group.id])
    end
  end

  let(:group_namespace_2) do
    namespaces.create!(name: 'group_2', path: 'group_2', type: 'Group').tap do |group|
      group.update!(traversal_ids: [group.id])
    end
  end

  let(:project_namespace_1) { namespaces.create!(name: '1', path: '1', type: 'Project', parent_id: group_namespace_1) }
  let(:project_namespace_2) { namespaces.create!(name: '2', path: '2', type: 'Project', parent_id: group_namespace_2) }
  let(:project_namespace_3) { namespaces.create!(name: '3', path: '3', type: 'Project', parent_id: group_namespace_2) }

  let(:policy_project_namespace) { namespaces.create!(name: '4', path: '4', type: 'Project') }
  let(:policy_project) do
    projects.create!(
      name: 'Policy Project',
      namespace_id: policy_project_namespace.id,
      project_namespace_id: policy_project_namespace.id
    )
  end

  let(:project_1) { projects.create!(namespace_id: group_namespace_1.id, project_namespace_id: project_namespace_1.id) }
  let(:project_2) { projects.create!(namespace_id: group_namespace_2.id, project_namespace_id: project_namespace_2.id) }
  let(:project_3) { projects.create!(namespace_id: group_namespace_2.id, project_namespace_id: project_namespace_3.id) }

  let(:project_policy_configuration) { create_policy_configuration(project_id: project_1.id) }
  let(:namespace_policy_configuration_1) { create_policy_configuration(namespace_id: group_namespace_1.id) }
  let(:namespace_policy_configuration_2) { create_policy_configuration(namespace_id: group_namespace_2.id) }

  describe '#up' do
    it 'enqueues ProcessScanResultPolicyWorker for each project of policy configuration namespace' do
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(project_1.id,
        namespace_policy_configuration_1.id)
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(project_2.id,
        namespace_policy_configuration_2.id)
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).with(project_3.id,
        namespace_policy_configuration_2.id)

      migrate!
    end
  end

  def create_policy_configuration(policy_project_id: policy_project.id, project_id: nil, namespace_id: nil)
    security_orchestration_policy_configurations.create!(
      project_id: project_id,
      namespace_id: namespace_id,
      security_policy_management_project_id: policy_project_id
    )
  end
end
