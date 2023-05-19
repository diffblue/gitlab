# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncProjectWorker, feature_category: :security_policy_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  let(:worker) { Security::ProcessScanResultPolicyWorker }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [configuration.project.id] }
  end

  describe '#perform' do
    let(:project_id) { project.id }

    subject(:perform) { described_class.new.perform(project_id) }

    before do
      stub_licensed_features(security_orchestration_policies: true)

      allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 3) do |instance|
        allow(instance).to receive(:policy_configuration_valid?).and_return(true)
      end
    end

    context 'without project' do
      let(:project_id) { 'invalid_id' }

      it 'does not execute ProcessScanResultPolicyWorker' do
        expect(worker).not_to receive(:perform_async)

        perform
      end
    end

    context 'with project without configuration' do
      let_it_be(:project) { create(:project) }

      it 'does not execute ProcessScanResultPolicyWorker' do
        expect(worker).not_to receive(:perform_async)

        perform
      end
    end

    context 'with associated project-level policy configuration' do
      it 'executes ProcessScanResultPolicyWorker' do
        expect(worker).to receive(:perform_in).with(0, project.id, configuration.id)

        perform
      end

      context 'with feature disabled' do
        before do
          stub_licensed_features(security_orchestration_policies: false)
        end

        it 'does not execute ProcessScanResultPolicyWorker' do
          expect(worker).not_to receive(:perform_in)

          perform
        end
      end
    end

    context 'with group-level configuration' do
      let_it_be(:group_configuration) do
        create(:security_orchestration_policy_configuration, :namespace, namespace: group)
      end

      it 'executes ProcessScanResultPolicyWorker' do
        expect(worker).to receive(:perform_in).with(0, project.id, configuration.id).ordered
        expect(worker).to receive(:perform_in).with(30, project.id, group_configuration.id).ordered

        perform
      end
    end
  end
end
