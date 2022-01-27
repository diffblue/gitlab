# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::PolicyCommitService do
  include RepoHelpers

  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { project.first_owner }
    let_it_be(:policy_management_project) { create(:project, :repository, creator: current_user) }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, security_policy_management_project: policy_management_project, project: project) }

    let(:policy_hash) { build(:scan_execution_policy, name: 'Test Policy') }
    let(:input_policy_yaml) { policy_hash.merge(type: 'scan_execution_policy').to_yaml }
    let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy_hash])}
    let(:policy_name) { policy_hash[:name] }

    let(:operation) { :append }
    let(:params) { { policy_yaml: input_policy_yaml, name: policy_name, operation: operation } }

    subject(:service) do
      described_class.new(project: project, current_user: current_user, params: params)
    end

    around do |example|
      Timecop.scale(60) { example.run }
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
        create_file_in_repo(
          policy_management_project,
          policy_management_project.default_branch_or_main,
          policy_management_project.default_branch_or_main,
          Security::OrchestrationPolicyConfiguration::POLICY_PATH,
          policy_yaml
        )
        policy_configuration.security_policy_management_project.add_developer(current_user)
        policy_configuration.clear_memoization(:policy_hash)
        policy_configuration.clear_memoization(:policy_blob)
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
        let(:input_policy_yaml) { build(:scan_execution_policy, name: 'Updated Policy').merge(type: 'scan_execution_policy').to_yaml }
        let(:policy_name) { 'Test Policy' }

        it 'creates branch with updated policy' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:branch]).not_to be_nil

          updated_policy_blob = policy_management_project.repository.blob_data_at(response[:branch], Security::OrchestrationPolicyConfiguration::POLICY_PATH)
          updated_policy_yaml = Gitlab::Config::Loader::Yaml.new(updated_policy_blob).load!
          expect(updated_policy_yaml[:scan_execution_policy][0][:name]).to eq('Updated Policy')
        end
      end

      context 'remove' do
        let(:operation) { :remove }

        it 'creates branch with removed policy' do
          response = service.execute

          expect(response[:status]).to eq(:success)
          expect(response[:branch]).not_to be_nil

          updated_policy_blob = policy_management_project.repository.blob_data_at(response[:branch], Security::OrchestrationPolicyConfiguration::POLICY_PATH)
          updated_policy_yaml = Gitlab::Config::Loader::Yaml.new(updated_policy_blob).load!
          expect(updated_policy_yaml[:scan_execution_policy]).to be_empty
        end
      end
    end
  end
end
