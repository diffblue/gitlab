# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::PolicyCommitService do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { project.owner }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }

    let(:policy_hash) { build(:scan_execution_policy, name: 'Test Policy') }
    let(:input_policy_yaml) { policy_hash.merge(type: 'scan_execution_policy').to_yaml }
    let(:policy_yaml) { build(:scan_execution_policy_yaml, policies: [policy_hash])}

    let(:operation) { :append }
    let(:params) { { policy_yaml: input_policy_yaml, operation: operation } }

    subject(:service) do
      described_class.new(project: project, current_user: current_user, params: params)
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
      end
    end

    context 'when policy_yaml is invalid' do
      let(:invalid_input_policy_yaml) do
        <<-EOS
          invalid_name: invalid
          type: scan_execution_policy
        EOS
      end

      let(:params) { { policy_yaml: invalid_input_policy_yaml, operation: operation } }

      it 'returns error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq("Invalid policy yaml")
      end
    end

    context 'when security_orchestration_policies_configuration does not exist for project' do
      let_it_be(:project) { create(:project) }

      it 'does not create new project' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Security Policy Project does not exist')
      end
    end

    context 'when policy already exists in policy project' do
      before do
        allow_next_instance_of(::Files::UpdateService) do |instance|
          allow(instance).to receive(:execute).and_return({ status: :success })
        end

        policy_configuration.security_policy_management_project.add_developer(current_user)
      end

      context 'append' do
        it 'does not create branch' do
          response = service.execute

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to eq("Policy already exists with same name")
        end
      end

      context 'replace' do
        let(:operation) { :replace }

        it 'creates branch' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:branch]).not_to be_nil
        end
      end

      context 'remove' do
        let(:operation) { :remove }

        it 'creates branch' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:branch]).not_to be_nil
        end
      end
    end
  end
end
