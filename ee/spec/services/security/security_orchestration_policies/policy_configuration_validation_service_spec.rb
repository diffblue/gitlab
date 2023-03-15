# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::PolicyConfigurationValidationService,
  feature_category: :security_policy_management do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }

    let(:policy) { build(:scan_execution_policy) }
    let(:policy_blob) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }
    let(:type) { :scan_execution_policy }

    subject(:service) do
      described_class.new(policy_configuration: policy_configuration, type: type)
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).and_return(policy_blob)
      end
    end

    context 'when all components are valid' do
      it 'returns success' do
        response = service.execute

        expect(response[:status]).to eq(:success)
      end
    end

    context 'when security_orchestration_policies_configuration is missing' do
      let(:policy_configuration) { nil }

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Project does not have a policy configuration')
        expect(response[:invalid_component]).to eq(:policy_configuration)
      end
    end

    context 'when security_orchestration_policies_configuration is invalid' do
      let(:policy_blob) { { scan_execution_policy: 'invalid' }.to_yaml }

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Could not fetch policy because existing policy YAML is invalid')
        expect(response[:invalid_component]).to eq(:policy_yaml)
      end
    end

    context 'when type parameter is missing' do
      let(:type) { nil }

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('type parameter is missing and is required')
        expect(response[:invalid_component]).to eq(:parameter)
      end
    end

    context 'when retrieving an invalid policy type' do
      let(:type) { :invalid }

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Invalid policy type')
        expect(response[:invalid_component]).to eq(:parameter)
      end
    end

    context 'when policy.yml is empty' do
      let(:policy_blob) { {}.to_yaml }

      it 'returns an error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq("Policy management project does not have any policies in #{::Security::OrchestrationPolicyConfiguration::POLICY_PATH}")
        expect(response[:invalid_component]).to eq(:policy_project)
      end
    end
  end
end
