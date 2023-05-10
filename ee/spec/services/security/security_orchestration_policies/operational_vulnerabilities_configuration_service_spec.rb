# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::OperationalVulnerabilitiesConfigurationService,
  feature_category: :security_policy_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:object) { create(:project, group: group) }

  let(:relationship) { nil }
  let(:action_scan_types) { nil }
  let(:policy) { build(:scan_execution_policy) }
  let(:result_policy) { build(:scan_result_policy) }
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

  let(:agent) { create(:cluster_agent, project: object) }
  let(:other_agent) { create(:cluster_agent) }

  subject { described_class.new(agent).execute }

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

      context 'when agent project has security_orchestration_policy project' do
        context 'when policy is not applicable for agent' do
          let(:policy) { build(:scan_execution_policy, :with_schedule_and_agent, agent: other_agent) }

          it 'returns empty response' do
            is_expected.to be_empty
          end
        end

        context 'when policy is applicable for agent' do
          let(:policy) { build(:scan_execution_policy, :with_schedule_and_agent, agent: agent) }

          it 'returns matching configuration' do
            is_expected.to match_array(
              [{ cadence: '30 2 * * *', namespaces: %w[namespace-a namespace-b], config: policy_configuration }]
            )
          end
        end

        context 'when policy is configured on the group level' do
          let!(:policy_configuration) do
            create(
              :security_orchestration_policy_configuration,
              :namespace,
              security_policy_management_project: policy_management_project,
              namespace: group
            )
          end

          context 'when policy is applicable for agent' do
            let(:policy) { build(:scan_execution_policy, :with_schedule_and_agent, agent: agent) }

            it 'returns matching configuration' do
              is_expected.to match_array(
                [{ cadence: '30 2 * * *', namespaces: %w[namespace-a namespace-b], config: policy_configuration }]
              )
            end
          end
        end
      end

      context 'when agent project is different from security_orchestration_policy project' do
        let(:agent) { create(:cluster_agent, project: create(:project)) }

        it 'returns empty response' do
          is_expected.to be_empty
        end
      end
    end
  end
end
