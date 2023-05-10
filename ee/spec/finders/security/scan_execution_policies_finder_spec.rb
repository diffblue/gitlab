# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanExecutionPoliciesFinder, feature_category: :security_policy_management do
  let!(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }
  let!(:policy_yaml) do
    build(:orchestration_policy_yaml, scan_execution_policy: [policy])
  end

  include_context 'with scan policies information'

  subject { described_class.new(actor, object, params).execute }

  context 'when actor is Clusters::Agent' do
    let_it_be(:actor) { create(:cluster_agent, project: object) }

    before do
      stub_licensed_features(security_orchestration_policies: true)
    end

    context 'when agent project has security_orchestration_policy project' do
      it 'returns policy matching the given scan type' do
        is_expected.to match_array([policy.merge(
          {
            config: policy_configuration,
            project: object,
            namespace: nil,
            inherited: false
          })])
      end
    end

    context 'when the security policy project is linked to the group' do
      let!(:policy_configuration) do
        create(
          :security_orchestration_policy_configuration,
          :namespace,
          security_policy_management_project: policy_management_project,
          namespace: group
        )
      end

      let(:relationship) { :inherited }

      it 'returns policy matching the given scan type' do
        is_expected.to match_array([policy.merge(
          {
            config: policy_configuration,
            project: nil,
            namespace: group,
            inherited: true
          })])
      end

      context 'and object is not a Project' do
        let(:object) { group }

        it 'returns empty response' do
          is_expected.to be_empty
        end
      end
    end
  end

  context 'when action_scan_types is given' do
    before do
      stub_licensed_features(security_orchestration_policies: true)
    end

    context 'when there are multiple policies' do
      let(:secret_detection_policy) do
        build(
          :scan_execution_policy,
          name: 'Run secret detection in every pipeline',
          description: 'Secret detection',
          actions: [{ scan: 'secret_detection' }]
        )
      end

      let(:policy_yaml) do
        build(
          :orchestration_policy_yaml,
          scan_execution_policy: [policy, secret_detection_policy]
        )
      end

      let(:action_scan_types) { [::Types::Security::ReportTypeEnum.values['DAST'].value] }

      it 'returns policy matching the given scan type' do
        is_expected.to match_array([policy.merge(
          {
            config: policy_configuration,
            project: object,
            namespace: nil,
            inherited: false
          })])
      end
    end

    context 'when there are no matching policies' do
      let(:action_scan_types) { [::Types::Security::ReportTypeEnum.values['CONTAINER_SCANNING'].value] }

      it 'returns empty response' do
        is_expected.to be_empty
      end
    end
  end

  it_behaves_like 'scan policies finder'
end
