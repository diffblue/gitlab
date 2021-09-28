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
    let(:policy) { build(:scan_execution_policy, enabled: true, rules: [rule]) }
    let(:rule) { { type: 'schedule', branches: %w[master production], cadence: '*/20 * * * *' } }

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
        allow(instance).to receive(:active_scan_execution_policies).and_return([policy])
      end
    end

    context 'when scan type is dast' do
      it 'invokes AppSec::Dast::Scans::CreateService' do
        expect(::AppSec::Dast::Scans::CreateService).to receive(:new).twice.and_call_original

        service.execute(schedule)
      end
    end

    context 'when scan type is secret_detection' do
      before do
        policy[:actions] = [{ scan: 'secret_detection' }]
      end

      it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService' do
        expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to receive(:new).twice.and_call_original

        service.execute(schedule)
      end
    end

    context 'when scan type is cluster_image_scanning' do
      before do
        policy[:actions] = [{ scan: 'cluster_image_scanning' }]
      end

      context 'when clusters are not defined in the rule' do
        it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService' do
          expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to(
            receive(:new)
            .with(project: project, current_user: current_user, params: { action: policy[:actions].first.merge(clusters: nil), branch: project.default_branch_or_main })
            .and_call_original)

          service.execute(schedule)
        end
      end

      context 'when clusters are defined in the rule' do
        let(:rule) { { type: 'schedule', clusters: { production: {} }, cadence: '*/20 * * * *' } }

        it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService' do
          expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to(
            receive(:new)
            .with(project: project, current_user: current_user, params: { action: policy[:actions].first.merge(clusters: { production: {} }), branch: project.default_branch_or_main })
            .and_call_original)

          service.execute(schedule)
        end
      end
    end

    context 'when scan type is container_scanning' do
      before do
        policy[:actions] = [{ scan: 'container_scanning' }]
      end

      context 'when clusters are not defined in the rule' do
        it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService for both branches' do
          expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to(
            receive(:new)
            .with(project: project, current_user: current_user, params: { action: policy[:actions].first, branch: 'master' })
            .and_call_original)

          expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to(
            receive(:new)
            .with(project: project, current_user: current_user, params: { action: policy[:actions].first, branch: 'production' })
            .and_call_original)

          service.execute(schedule)
        end
      end

      context 'when clusters are defined in the rule' do
        let(:rule) { { type: 'schedule', clusters: { production: {} }, cadence: '*/20 * * * *' } }

        it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService for single cluster only' do
          expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to(
            receive(:new)
            .with(project: project, current_user: current_user, params: { action: policy[:actions].first.merge(scan: 'cluster_image_scanning', clusters: { production: {} }), branch: project.default_branch_or_main })
            .and_call_original)

          service.execute(schedule)
        end
      end

      it 'invokes Security::SecurityOrchestrationPolicies::CreatePipelineService' do
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
        build(:scan_execution_policy,
                           enabled: true,
                           rules: [{ type: 'schedule', branches: %w[invalid_branch], cadence: '*/20 * * * *' }])
      end

      it_behaves_like 'does not execute scan'
    end

    context 'when policy actions does not exist' do
      let(:policy) { build(:scan_execution_policy, :with_schedule, enabled: true, actions: []) }

      it_behaves_like 'does not execute scan'
    end

    context 'when policy scan type is invalid' do
      let(:policy) { build(:scan_execution_policy, :with_schedule, enabled: true, actions: [{ scan: 'invalid' }]) }

      it_behaves_like 'does not execute scan'
    end

    context 'when policy does not exist' do
      let(:policy) { nil }

      it_behaves_like 'does not execute scan'
    end
  end
end
