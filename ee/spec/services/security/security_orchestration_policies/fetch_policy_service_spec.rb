# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::FetchPolicyService, feature_category: :security_policy_management do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let(:policy) { build(:scan_execution_policy) }
    let(:policy_blob) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }
    let(:type) { :scan_execution_policy }
    let(:name) { policy[:name] }

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
