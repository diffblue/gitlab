# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::RuleScheduleService do
  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:current_user) { project.users.first }
    let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: policy_configuration) }
    let!(:scanner_profile) { create(:dast_scanner_profile, name: 'Scanner Profile', project: project) }
    let!(:site_profile) { create(:dast_site_profile, name: 'Site Profile', project: project) }
    let(:policy) do
      {
        name: 'Run DAST in every pipeline',
        description: 'This policy enforces to run DAST for every pipeline within the project',
        enabled: true,
        rules: [{ type: 'schedule', branches: %w[master production], cadence: '*/20 * * * *' }],
        actions: [
          { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
        ]
      }
    end

    subject(:service) { described_class.new(container: project, current_user: current_user) }

    shared_examples 'does not execute scan' do
      it 'does not create scan pipeline but updates next_run_at' do
        expect { service.execute(schedule) }.to change(Ci::Pipeline, :count).by(0)

        expect(schedule.next_run_at).to be > Time.zone.now
      end
    end

    before do
      stub_licensed_features(security_on_demand_scans: true)

      project.repository.create_branch('production', project.default_branch)

      allow_next_instance_of(Security::OrchestrationPolicyConfiguration) do |instance|
        allow(instance).to receive(:active_policies).and_return([policy])
      end
    end

    context 'when scan type is dast' do
      it 'invokes DastOnDemandScans::CreateService' do
        expect(::DastOnDemandScans::CreateService).to receive(:new).twice.and_call_original

        service.execute(schedule)
      end
    end

    context 'when scan type is secret_detection' do
      it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService' do
        policy[:actions] = [{ scan: 'secret_detection' }]
        expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to receive(:new).twice.and_call_original

        service.execute(schedule)
      end
    end

    context 'when policy actions exists and there are multiple matching branches' do
      it 'creates multiple scan pipelines and updates next_run_at' do
        expect { service.execute(schedule) }.to change(Ci::Pipeline, :count).by(2)

        expect(schedule.next_run_at).to be > Time.zone.now
      end
    end

    context 'when the branch in rules does not exist' do
      let(:policy) do
        {
          name: 'Run DAST in every pipeline',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'schedule', branches: %w[invalid_branch], cadence: '*/20 * * * *' }],
          actions: []
        }
      end

      it_behaves_like 'does not execute scan'
    end

    context 'when policy actions does not exist' do
      let(:policy) do
        {
          name: 'Run DAST in every pipeline',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *' }],
          actions: []
        }
      end

      it_behaves_like 'does not execute scan'
    end

    context 'when policy scan type is invalid' do
      let(:policy) do
        {
          name: 'Run DAST in every pipeline',
          description: 'This policy enforces to run DAST for every pipeline within the project',
          enabled: true,
          rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *' }],
          actions: [
            { scan: 'invalid' }
          ]
        }
      end

      it_behaves_like 'does not execute scan'
    end

    context 'when policy does not exist' do
      let(:policy) { nil }

      it_behaves_like 'does not execute scan'
    end
  end
end
