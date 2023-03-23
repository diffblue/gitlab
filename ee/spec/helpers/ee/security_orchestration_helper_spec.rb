# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::SecurityOrchestrationHelper, feature_category: :security_policy_management do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_reload(:namespace) { create(:group, :public) }

  describe '#can_update_security_orchestration_policy_project?' do
    let(:owner) { project.first_owner }

    before do
      allow(helper).to receive(:current_user) { owner }
    end

    it 'returns false when user cannot update security orchestration policy project' do
      allow(helper).to receive(:can?).with(owner, :update_security_orchestration_policy_project, project) { false }
      expect(helper.can_update_security_orchestration_policy_project?(project)).to eq false
    end

    it 'returns true when user can update security orchestration policy project' do
      allow(helper).to receive(:can?).with(owner, :update_security_orchestration_policy_project, project) { true }
      expect(helper.can_update_security_orchestration_policy_project?(project)).to eq true
    end
  end

  describe '#assigned_policy_project' do
    context 'for project' do
      subject { helper.assigned_policy_project(project) }

      context 'when a project does have a security policy project' do
        let_it_be(:policy_management_project) { create(:project) }

        let_it_be(:security_orchestration_policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            security_policy_management_project: policy_management_project, project: project
          )
        end

        it 'include information about policy management project' do
          is_expected.to include(
            id: policy_management_project.to_global_id.to_s,
            name: policy_management_project.name,
            full_path: policy_management_project.full_path,
            branch: policy_management_project.default_branch_or_main
          )
        end
      end

      context 'when a project does not have a security policy project' do
        subject { helper.assigned_policy_project(project) }

        it { is_expected.to be_nil }
      end
    end

    context 'for namespace' do
      subject { helper.assigned_policy_project(project) }

      context 'when a namespace does have a security policy project' do
        let_it_be(:policy_management_project) { create(:project) }
        let_it_be(:security_orchestration_policy_configuration) do
          create(
            :security_orchestration_policy_configuration, :namespace,
            security_policy_management_project: policy_management_project, namespace: namespace
          )
        end

        subject { helper.assigned_policy_project(namespace) }

        it 'include information about policy management project' do
          is_expected.to include({
            id: policy_management_project.to_global_id.to_s,
            name: policy_management_project.name,
            full_path: policy_management_project.full_path,
            branch: policy_management_project.default_branch_or_main
          })
        end
      end

      context 'when a namespace does not have a security policy project' do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '#orchestration_policy_data' do
    context 'for project' do
      let(:approvers) { %w(approver1 approver2) }
      let(:owner) { project.first_owner }
      let(:policy) { nil }
      let(:policy_type) { 'scan_execution_policy' }
      let_it_be(:mit_license) { create(:software_license, :mit) }
      let_it_be(:apache_license) { create(:software_license, :apache_2_0) }
      let(:base_data) do
        {
          assigned_policy_project: nil.to_json,
          disable_scan_policy_update: 'false',
          create_agent_help_path: kind_of(String),
          namespace_id: project.id,
          namespace_path: kind_of(String),
          policy_editor_empty_state_svg_path: kind_of(String),
          policies_path: kind_of(String),
          policy: policy&.to_json,
          policy_type: policy_type,
          role_approver_types: Gitlab::Access.sym_options_with_owner.keys.map(&:to_s),
          scan_policy_documentation_path: kind_of(String),
          scan_result_approvers: approvers&.to_json,
          software_licenses: [apache_license.name, mit_license.name],
          global_group_approvers_enabled:
            Gitlab::CurrentSettings.security_policy_global_group_approvers_enabled.to_json,
          root_namespace_path: project.root_ancestor.full_path
        }
      end

      before do
        allow(helper).to receive(:current_user) { owner }
        allow(helper).to receive(:can?).with(owner, :modify_security_policy, project) { true }
      end

      subject { helper.orchestration_policy_data(project, policy_type, policy, approvers) }

      context 'when a new policy is being created' do
        let(:policy) { nil }
        let(:policy_type) { nil }
        let(:approvers) { nil }

        it { is_expected.to match(base_data) }
      end

      context 'when an existing policy is being edited' do
        let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }

        it { is_expected.to match(base_data) }
      end

      context 'when scan policy update is disabled' do
        before do
          allow(helper).to receive(:can?).with(owner, :modify_security_policy, project) { false }
        end

        it { is_expected.to match(base_data.merge(disable_scan_policy_update: 'true')) }
      end

      context 'when a project does have a security policy project' do
        let_it_be(:policy_management_project) { create(:project) }

        let_it_be(:security_orchestration_policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            security_policy_management_project: policy_management_project, project: project
          )
        end

        it 'include information about policy management project' do
          is_expected.to match(base_data.merge(assigned_policy_project: {
            id: policy_management_project.to_global_id.to_s,
            name: policy_management_project.name,
            full_path: policy_management_project.full_path,
            branch: policy_management_project.default_branch_or_main
          }.to_json))
        end
      end
    end

    context 'for namespace' do
      let_it_be(:mit_license) { create(:software_license, :mit) }
      let_it_be(:apache_license) { create(:software_license, :apache_2_0) }

      let(:approvers) { %w(approver1 approver2) }
      let(:owner) { namespace.first_owner }
      let(:policy) { nil }
      let(:policy_type) { 'scan_execution_policy' }
      let(:base_data) do
        {
          assigned_policy_project: nil.to_json,
          disable_scan_policy_update: 'false',
          policy: policy&.to_json,
          policy_editor_empty_state_svg_path: kind_of(String),
          policy_type: policy_type,
          policies_path: kind_of(String),
          role_approver_types: Gitlab::Access.sym_options_with_owner.keys.map(&:to_s),
          scan_policy_documentation_path: kind_of(String),
          namespace_path: namespace.full_path,
          namespace_id: namespace.id,
          scan_result_approvers: approvers&.to_json,
          software_licenses: [apache_license.name, mit_license.name],
          global_group_approvers_enabled:
            Gitlab::CurrentSettings.security_policy_global_group_approvers_enabled.to_json,
          root_namespace_path: namespace.root_ancestor.full_path
        }
      end

      before do
        allow(helper).to receive(:current_user) { owner }
        allow(helper).to receive(:can?).with(owner, :modify_security_policy, namespace) { true }
      end

      subject { helper.orchestration_policy_data(namespace, policy_type, policy, approvers) }

      context 'when a new policy is being created' do
        let(:policy) { nil }
        let(:policy_type) { nil }
        let(:approvers) { nil }

        it { is_expected.to match(base_data) }
      end

      context 'when an existing policy is being edited' do
        let(:policy_type) { 'scan_execution_policy' }

        let(:policy) do
          build(:scan_execution_policy, name: 'Run DAST in every pipeline')
        end

        it { is_expected.to match(base_data) }
      end

      context 'when scan policy update is disabled' do
        before do
          allow(helper).to receive(:can?)
            .with(owner, :modify_security_policy, namespace)
            .and_return(false)
        end

        it { is_expected.to match(base_data.merge(disable_scan_policy_update: 'true')) }
      end

      context 'when a namespace does have a security policy project' do
        let_it_be(:policy_management_project) { create(:project) }

        let_it_be(:security_orchestration_policy_configuration) do
          create(
            :security_orchestration_policy_configuration, :namespace,
            security_policy_management_project: policy_management_project, namespace: namespace
          )
        end

        it 'include information about policy management project' do
          is_expected.to match(base_data.merge(assigned_policy_project: {
            id: policy_management_project.to_global_id.to_s,
            name: policy_management_project.name,
            full_path: policy_management_project.full_path,
            branch: policy_management_project.default_branch_or_main
          }.to_json))
        end
      end
    end
  end
end
