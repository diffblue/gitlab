# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::FetchPolicyService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }

    let(:policy) do
      {
        name: 'Run DAST in every pipeline',
        description: 'This policy enforces to run DAST for every pipeline within the project',
        enabled: true,
        rules: [{ type: 'pipeline', branches: %w[production] }],
        actions: [
          { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
        ]
      }
    end

    let(:policy_blob) { { scan_execution_policy: [policy] }.to_yaml }
    let(:type) { :scan_execution_policy }
    let(:name) { 'Run DAST in every pipeline' }

    subject(:service) do
      described_class.new(policy_configuration: policy_configuration, name: name, type: type)
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).and_return(policy_blob)
      end
    end

    context 'when retrieving an existing policy by name' do
      it 'returns policy' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:policy]).to eq(policy)
      end
    end

    context 'when retrieving an non-existing policy by name' do
      let(:name) { 'Invalid name' }

      it 'returns nil' do
        response = service.execute

        expect(response[:status]).to eq(:success)
        expect(response[:policy]).to eq(nil)
      end
    end
  end
end
