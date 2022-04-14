# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::SecurityOrchestrationHelper do
  let_it_be_with_reload(:namespace) { create(:group, :public) }

  describe '#security_orchestration_policy_data' do
    let(:approvers) { %w(approver1 approver2) }
    let(:owner) { namespace.first_owner }
    let(:base_data) do
      {
        assigned_policy_project: nil.to_json,
        disable_scan_policy_update: false.to_s,
        create_agent_help_path: kind_of(String),
        policy: policy&.to_json,
        policy_editor_empty_state_svg_path: kind_of(String),
        policy_type: policy_type,
        policies_path: nil,
        scan_policy_documentation_path: kind_of(String),
        scan_result_approvers: approvers&.to_json
      }
    end

    before do
      allow(helper).to receive(:current_user) { owner }
    end

    subject { helper.security_orchestration_policy_data(namespace, policy_type, policy, approvers) }

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
  end
end
