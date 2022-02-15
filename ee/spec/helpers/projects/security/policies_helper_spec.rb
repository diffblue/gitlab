# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::PoliciesHelper do
  let_it_be_with_reload(:project) { create(:project, :repository, :public) }

  describe '#assigned_policy_project' do
    context 'when a project does have a security policy project' do
      let_it_be(:policy_management_project) { create(:project) }

      subject { helper.assigned_policy_project(project) }

      it {
        create(:security_orchestration_policy_configuration,
          { security_policy_management_project: policy_management_project, project: project }
        )

        is_expected.to include({
          id: policy_management_project.to_global_id.to_s,
          name: policy_management_project.name,
          full_path: policy_management_project.full_path,
          branch: policy_management_project.default_branch_or_main
        })
      }
    end

    context 'when a project does not have a security policy project' do
      subject { helper.assigned_policy_project(project) }

      it {
        is_expected.to be_nil
      }
    end
  end

  describe '#orchestration_policy_data' do
    let(:approvers) { %w(approver1 approver2) }
    let(:owner) { project.first_owner }
    let(:base_data) do
      {
        assigned_policy_project: "null",
        default_environment_id: -1,
        disable_scan_policy_update: "false",
        network_policies_endpoint: kind_of(String),
        create_agent_help_path: kind_of(String),
        environments_endpoint: kind_of(String),
        network_documentation_path: kind_of(String),
        policy_editor_empty_state_svg_path: kind_of(String),
        project_path: project.full_path,
        project_id: project.id,
        policies_path: kind_of(String),
        environment_id: environment&.id,
        policy: policy&.to_json,
        policy_type: policy_type,
        scan_policy_documentation_path: kind_of(String),
        scan_result_approvers: approvers&.to_json
      }
    end

    before do
      allow(helper).to receive(:current_user) { owner }
      allow(helper).to receive(:can?).with(owner, :update_security_orchestration_policy_project, project) { true }
    end

    subject { helper.orchestration_policy_data(project, policy_type, policy, environment, approvers) }

    context 'when a new policy is being created' do
      let(:environment) { nil }
      let(:policy) { nil }
      let(:policy_type) { nil }
      let(:approvers) { nil }

      it { is_expected.to match(base_data) }
    end

    context 'when an existing policy is being edited' do
      let_it_be(:environment) { create(:environment, project: project) }

      let(:policy_type) { 'container_policy' }

      let(:policy) do
        Gitlab::Kubernetes::CiliumNetworkPolicy.new(
          name: 'policy',
          namespace: 'another',
          selector: { matchLabels: { role: 'db' } },
          ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }]
        )
      end

      it { is_expected.to match(base_data.merge(default_environment_id: project.default_environment.id)) }
    end
  end
end
