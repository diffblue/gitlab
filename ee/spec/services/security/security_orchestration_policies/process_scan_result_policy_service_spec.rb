# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService do
  describe '#execute' do
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration) }

    let(:approver) { create(:user) }
    let(:policy) { build(:scan_result_policy, name: 'Test Policy') }
    let(:policy_yaml) { Gitlab::Config::Loader::Yaml.new(policy.to_yaml).load! }
    let(:project) { policy_configuration.project }
    let(:service) { described_class.new(policy_configuration: policy_configuration, policy: policy) }

    before do
      allow(policy_configuration).to receive(:policy_last_updated_by).and_return(project.owner)
    end

    subject { service.execute }

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(scan_result_policy: false)
      end

      it 'does not change approval project rules' do
        expect { subject }.not_to change { project.approval_rules.count }
      end
    end

    context 'without any require_approval action' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', actions: [{ type: 'another_one' }]) }

      it 'does not create approval project rules' do
        expect { subject }.not_to change { project.approval_rules.count }
      end
    end

    context 'without any rule of the scan_finding type' do
      let(:policy) { build(:scan_result_policy, name: 'Test Policy', rules: [{ type: 'another_one' }]) }

      it 'does not create approval project rules' do
        expect { subject }.not_to change { project.approval_rules.count }
      end
    end

    it 'creates a new project approval rule' do
      expect { subject }.to change { project.approval_rules.count }.by(1)
    end

    it 'sets project approval rules names based on policy name', :aggregate_failures do
      subject

      scan_finding_rule = project.approval_rules.first
      first_rule = policy[:rules].first
      first_action = policy[:actions].first

      expect(policy[:name]).to include(scan_finding_rule.name)
      expect(scan_finding_rule.report_type).to eq(Security::ScanResultPolicy::SCAN_FINDING)
      expect(scan_finding_rule.rule_type).to eq('report_approver')
      expect(scan_finding_rule.scanners).to eq(first_rule[:scanners])
      expect(scan_finding_rule.severity_levels).to eq(first_rule[:severity_levels])
      expect(scan_finding_rule.vulnerabilities_allowed).to eq(first_rule[:vulnerabilities_allowed])
      expect(scan_finding_rule.approvals_required).to eq(first_action[:approvals_required])
    end
  end
end
