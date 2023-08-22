# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanExecutionPolicies::RuleScheduleWorker, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  let_it_be(:schedule) do
    create(:security_orchestration_policy_rule_schedule,
      security_orchestration_policy_configuration: security_orchestration_policy_configuration)
  end

  let(:project_id) { project.id }
  let(:user_id) { user.id }
  let(:schedule_id) { schedule.id }

  shared_examples_for 'does not call RuleScheduleService' do
    it do
      expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

      subject
    end
  end

  describe '#perform' do
    subject { described_class.new.perform(project_id, user_id, schedule_id) }

    context 'when rule_schedule exists' do
      it 'calls RuleScheduleService' do
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::RuleScheduleService,
          project: project,
          current_user: user
        ) do |service|
          expect(service).to receive(:execute).with(schedule).and_call_original
        end

        subject
      end
    end

    context 'when project is marked for deletion' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)

        project.update! marked_for_deletion_at: 1.day.ago, pending_delete: false
      end

      it_behaves_like 'does not call RuleScheduleService'
    end

    context 'when project is not found' do
      let(:project_id) { non_existing_record_id }

      it_behaves_like 'does not call RuleScheduleService'
    end

    context 'when user is not found' do
      let(:user_id) { non_existing_record_id }

      it_behaves_like 'does not call RuleScheduleService'
    end

    context 'when schedule is not found' do
      let(:schedule_id) { non_existing_record_id }

      it_behaves_like 'does not call RuleScheduleService'
    end
  end
end
