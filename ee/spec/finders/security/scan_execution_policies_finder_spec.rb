# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanExecutionPoliciesFinder do
  let_it_be(:group) { create(:group) }
  let_it_be(:object) { create(:project, group: group) }

  let(:relationship) { nil }
  let(:action_scan_types) { nil }
  let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }
  let(:result_policy) { build(:scan_result_policy, name: 'Contains security critical') }
  let(:policy_yaml) do
    build(:orchestration_policy_yaml, scan_execution_policy: [policy], scan_result_policy: [result_policy])
  end

  let!(:policy_management_project) do
    create(
      :project, :custom_repo,
      files: {
        '.gitlab/security-policies/policy.yml' => policy_yaml
      })
  end

  let!(:policy_configuration) do
    create(
      :security_orchestration_policy_configuration,
      security_policy_management_project: policy_management_project,
      project: object
    )
  end

  let(:params) do
    {
      relationship: relationship,
      action_scan_types: action_scan_types
    }
  end

  let(:actor) { policy_management_project.first_owner }

  subject { described_class.new(actor, object, params).execute }

  describe '#execute' do
    context 'when feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when configuration is associated to project' do
        it 'returns policies with project' do
          is_expected.to match_array([policy.merge(
            {
              config: policy_configuration,
              project: object,
              namespace: nil,
              inherited: false
            })])
        end
      end

      context 'when configuration is associated to namespace' do
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
            is_expected.to be_empty
          end
        end

        context 'when relationship argument is provided as INHERITED' do
          let(:relationship) { :inherited }

          it 'returns scan execution policies for groups only' do
            is_expected.to match_array([policy.merge(
              {
                config: group_policy_configuration,
                project: nil,
                namespace: group,
                inherited: true
              })])
          end
        end
      end

      context 'when configuration is associated to project and namespace' do
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
            is_expected.to match_array([policy.merge(
              {
                config: policy_configuration,
                project: object,
                namespace: nil,
                inherited: false
              })])
          end
        end

        context 'when relationship argument is provided as INHERITED' do
          let(:relationship) { :inherited }

          it 'returns scan execution policies defined for both project and namespace' do
            is_expected.to match_array([
                                policy.merge({
                                  config: policy_configuration,
                                  project: object,
                                  namespace: nil,
                                  inherited: false
                                }),
                                policy.merge({
                                 config: group_policy_configuration,
                                 project: nil,
                                 namespace: group,
                                 inherited: true
                               })
            ])
          end
        end

        context 'when relationship argument is provided as INHERITED_ONLY' do
          let(:relationship) { :inherited_only }

          it 'returns scan execution policies defined for namespace onlt' do
            is_expected.to match_array([policy.merge(
              {
                config: group_policy_configuration,
                project: nil,
                namespace: group,
                inherited: true
              })])
          end
        end
      end

      context 'when user is unauthorized' do
        let(:actor) { create(:user) }

        it 'returns empty collection' do
          is_expected.to be_empty
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
            scan_execution_policy: [policy, secret_detection_policy],
            scan_result_policy: [result_policy]
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

    context 'when actor is Clusters::Agent' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when agent project has security_orchestration_policy project' do
        let(:actor) { create(:cluster_agent, project: object) }

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

      context 'when agent project is different from security_orchestration_policy project' do
        let(:actor) { create(:cluster_agent, project: create(:project)) }

        it 'returns empty response' do
          is_expected.to be_empty
        end
      end
    end
  end
end
