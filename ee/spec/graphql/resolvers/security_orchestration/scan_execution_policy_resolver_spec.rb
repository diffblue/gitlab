# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityOrchestration::ScanExecutionPolicyResolver do
  include GraphqlHelpers

  include_context 'orchestration policy context'

  let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }
  let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }
  let(:args) { {} }
  let(:expected_resolved) do
    [
      {
        name: 'Run DAST in every pipeline',
        description: 'This policy enforces to run DAST for every pipeline within the project',
        enabled: true,
        yaml: YAML.dump(policy.deep_stringify_keys),
        updated_at: policy_last_updated_at
      }
    ]
  end

  subject(:resolve_scan_policies) { resolve(described_class, obj: project, args: args, ctx: { current_user: user }) }

  it_behaves_like 'as an orchestration policy'

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

      let(:args) { { action_scan_types: [::Types::Security::ReportTypeEnum.values['DAST'].value] } }

      it 'returns policy matching the given scan type' do
        expect(resolve_scan_policies).to eq(expected_resolved)
      end
    end

    context 'when there are no matching policies' do
      let(:args) { { action_scan_types: [::Types::Security::ReportTypeEnum.values['CONTAINER_SCANNING'].value] } }

      it 'returns empty response' do
        expect(resolve_scan_policies).to be_empty
      end
    end
  end
end
