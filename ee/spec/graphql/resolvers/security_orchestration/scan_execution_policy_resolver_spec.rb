# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityOrchestration::ScanExecutionPolicyResolver do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let!(:policy_configuration) do
    create(
      :security_orchestration_policy_configuration,
      security_policy_management_project: policy_management_project,
      project: project
    )
  end

  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }
  let_it_be(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }

  let!(:policy_management_project) do
    create(
      :project, :custom_repo,
      files: {
        '.gitlab/security-policies/policy.yml' => policy_yaml
      })
  end

  let(:user) { policy_management_project.first_owner }

  let(:args) { {} }
  let(:expected_resolved) do
    [
      {
        name: 'Run DAST in every pipeline',
        description: 'This policy enforces to run DAST for every pipeline within the project',
        enabled: true,
        yaml: YAML.dump(policy.deep_stringify_keys),
        updated_at: policy_configuration.policy_last_updated_at,
        source: {
          project: project,
          namespace: nil,
          inherited: false
        }
      }
    ]
  end

  subject(:resolve_scan_policies) do
    resolve(described_class, obj: project, args: args, ctx: { current_user: user },
                             arg_style: :internal)
  end

  describe '#resolve' do
    context 'when feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'returns empty collection' do
        expect(resolve_scan_policies).to be_empty
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when policies are available for project only' do
        it 'returns scan execution policies' do
          expect(resolve_scan_policies).to eq(expected_resolved)
        end
      end

      context 'when policies are available for namespace only' do
        let!(:policy_configuration) { nil }

        let!(:group_policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            :namespace,
            security_policy_management_project: policy_management_project,
            namespace: group
          )
        end

        context 'when relationship argument is not provided' do
          it 'returns no scan execution policies' do
            expect(resolve_scan_policies).to be_empty
          end
        end

        context 'when relationship argument is provided as DIRECT' do
          let(:args) { { relationship: :direct } }

          it 'returns no scan execution policies' do
            expect(resolve_scan_policies).to be_empty
          end
        end

        context 'when relationship argument is provided as INHERITED' do
          let(:args) { { relationship: :inherited } }

          it 'returns scan execution policies for groups only' do
            expect(resolve_scan_policies).to eq(
              [
                {
                  name: 'Run DAST in every pipeline',
                  description: 'This policy enforces to run DAST for every pipeline within the project',
                  enabled: true,
                  yaml: YAML.dump(policy.deep_stringify_keys),
                  updated_at: group_policy_configuration.policy_last_updated_at,
                  source: {
                    project: nil,
                    namespace: group,
                    inherited: true
                  }
                }
              ])
          end
        end
      end

      context 'when policies are available for project and namespace' do
        let!(:group_policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            :namespace,
            security_policy_management_project: policy_management_project,
            namespace: group
          )
        end

        context 'when relationship argument is not provided' do
          it 'returns scan execution policies for project only' do
            expect(resolve_scan_policies).to eq(expected_resolved)
          end
        end

        context 'when relationship argument is provided as DIRECT' do
          let(:args) { { relationship: :direct } }

          it 'returns scan execution policies for project only' do
            expect(resolve_scan_policies).to eq(expected_resolved)
          end
        end

        context 'when relationship argument is provided as INHERITED' do
          let(:args) { { relationship: :inherited } }

          it 'returns scan execution policies defined for both project and namespace' do
            expect(resolve_scan_policies).to match_array(
              [
                {
                  name: 'Run DAST in every pipeline',
                  description: 'This policy enforces to run DAST for every pipeline within the project',
                  enabled: true,
                  yaml: YAML.dump(policy.deep_stringify_keys),
                  updated_at: policy_configuration.policy_last_updated_at,
                  source: {
                    project: project,
                    namespace: nil,
                    inherited: false
                  }
                },
                {
                  name: 'Run DAST in every pipeline',
                  description: 'This policy enforces to run DAST for every pipeline within the project',
                  enabled: true,
                  yaml: YAML.dump(policy.deep_stringify_keys),
                  updated_at: group_policy_configuration.policy_last_updated_at,
                  source: {
                    project: nil,
                    namespace: group,
                    inherited: true
                  }
                }
              ])
          end
        end
      end

      context 'when user is unauthorized' do
        let(:user) { create(:user) }

        it 'returns empty collection' do
          expect(resolve_scan_policies).to be_empty
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
