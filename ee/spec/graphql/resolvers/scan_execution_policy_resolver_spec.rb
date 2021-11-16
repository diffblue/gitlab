# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ScanExecutionPolicyResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:policy_management_project) { create(:project) }
  let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, security_policy_management_project: policy_management_project, project: project) }
  let_it_be(:policy_last_updated_at) { Time.now }
  let_it_be(:user) { policy_management_project.owner }

  let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }
  let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }

  let(:repository) { instance_double(Repository, root_ref: 'master', empty?: false) }
  let(:args) { {} }

  describe '#resolve' do
    subject(:resolve_scan_policies) { resolve(described_class, obj: project, args: args, ctx: { current_user: user }) }

    before do
      commit = create(:commit)
      commit.committed_date = policy_last_updated_at
      allow(policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).and_return(commit)
      allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'raises ResourceNotAvailable error' do
        expect { resolve_scan_policies }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      it 'returns scan execution policies' do
        expected_resolved = [
          {
            name: 'Run DAST in every pipeline',
            description: 'This policy enforces to run DAST for every pipeline within the project',
            enabled: true,
            yaml: YAML.dump(policy.deep_stringify_keys),
            updated_at: policy_last_updated_at
          }
        ]
        expect(resolve_scan_policies).to eq(expected_resolved)
      end

      context 'when user is unauthorized' do
        let(:user) { create(:user) }

        it 'raises ResourceNotAvailable error' do
          expect { resolve_scan_policies }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when action_scan_types is given' do
        context 'when there are multiple policies' do
          let(:secret_detection_policy) do
            build(
              :scan_execution_policy,
              name: 'Run secret detection in every pipeline',
              description: 'Secret detection',
              actions: [{ scan: 'secret_detection' }]
            )
          end

          let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy, secret_detection_policy]) }
          let(:args) { { action_scan_types: [::Types::Security::ReportTypeEnum.values['DAST'].value] } }

          it 'returns policy matching the given scan type' do
            expected_resolved = [
              {
                name: 'Run DAST in every pipeline',
                description: 'This policy enforces to run DAST for every pipeline within the project',
                enabled: true,
                yaml: YAML.dump(policy.deep_stringify_keys),
                updated_at: policy_last_updated_at
              }
            ]
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
  end
end
