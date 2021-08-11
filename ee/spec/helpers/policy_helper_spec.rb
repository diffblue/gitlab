# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PolicyHelper do
  let(:project) { create(:project, :repository, :public) }
  let(:environment) { create(:environment, project: project) }

  let(:policy) do
    Gitlab::Kubernetes::CiliumNetworkPolicy.new(
      name: 'policy',
      namespace: 'another',
      selector: { matchLabels: { role: 'db' } },
      ingress: [{ from: [{ namespaceSelector: { matchLabels: { project: 'myproject' } } }] }]
    )
  end

  let(:base_data) do
    {
      assigned_policy_project: "null",
      disable_scan_execution_update: "false",
      network_policies_endpoint: kind_of(String),
      configure_agent_help_path: kind_of(String),
      create_agent_help_path: kind_of(String),
      environments_endpoint: kind_of(String),
      project_path: project.full_path,
      project_id: project.id,
      threat_monitoring_path: kind_of(String)
    }
  end

  describe '#policy_details' do
    let(:owner) { project.owner }

    before do
      allow(helper).to receive(:current_user) { owner }
      allow(helper).to receive(:can?).with(owner, :update_security_orchestration_policy_project, project) { true }
    end

    context 'when a new policy is being created' do
      subject { helper.policy_details(project) }

      it 'returns expected policy data' do
        expect(subject).to match(base_data)
      end
    end

    context 'when an existing policy is being edited' do
      subject { helper.policy_details(project, policy, environment) }

      it 'returns expected policy data' do
        expect(subject).to match(
          base_data.merge(
            policy: policy.to_json,
            environment_id: environment.id
          )
        )
      end
    end

    context 'when no environment is passed in' do
      subject { helper.policy_details(project, policy) }

      it 'returns expected policy data' do
        expect(subject).to match(base_data)
      end
    end
  end

  describe '#policy_alert_details' do
    let(:alert) { build(:alert_management_alert, project: project) }

    context 'when a new alert is created' do
      subject { helper.threat_monitoring_alert_details_data(project, alert.iid) }

      it 'returns expected policy data' do
        expect(subject).to match({
          'alert-id' => alert.iid,
          'project-path' => project.full_path,
          'project-id' => project.id,
          'project-issues-path' => project_issues_path(project),
          'page' => 'THREAT_MONITORING'
        })
      end
    end
  end
end
