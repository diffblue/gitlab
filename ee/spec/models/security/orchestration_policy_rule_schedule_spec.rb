# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyRuleSchedule do
  describe 'associations' do
    it { is_expected.to belong_to(:owner).class_name('User') }
    it { is_expected.to belong_to(:security_orchestration_policy_configuration).class_name('Security::OrchestrationPolicyConfiguration') }
  end

  describe 'validations' do
    subject { create(:security_orchestration_policy_rule_schedule) }

    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to validate_presence_of(:security_orchestration_policy_configuration) }
    it { is_expected.to validate_presence_of(:cron) }
    it { is_expected.to validate_presence_of(:policy_index) }
    it { is_expected.to validate_presence_of(:rule_index) }
  end

  describe '.runnable_schedules' do
    subject { described_class.runnable_schedules }

    context 'when there are runnable schedules' do
      let!(:policy_rule_schedule) do
        travel_to(1.day.ago) do
          create(:security_orchestration_policy_rule_schedule)
        end
      end

      it 'returns the runnable schedule' do
        is_expected.to eq([policy_rule_schedule])
      end
    end

    context 'when there are no runnable schedules' do
      let!(:policy_rule_schedule) { }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'when there are runnable schedules in future' do
      let!(:policy_rule_schedule) do
        travel_to(1.day.from_now) do
          create(:security_orchestration_policy_rule_schedule)
        end
      end

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '#policy' do
    let(:rule_schedule) { create(:security_orchestration_policy_rule_schedule) }
    let(:policy_yaml) { { scan_execution_policy: [policy] }.to_yaml }

    subject { rule_schedule.policy }

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
      end
    end

    context 'when policy is present' do
      let(:policy) do
        {
          name: 'Scheduled DAST 1',
          description: 'This policy runs DAST for every 20 mins',
          enabled: true,
          rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *' }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        }
      end

      it { is_expected.to eq(policy) }
    end

    context 'when policy is not present' do
      let(:policy_yaml) { nil }

      it { is_expected.to be_nil }
    end

    context 'when policy is not enabled' do
      let(:policy) do
        {
          name: 'Scheduled DAST 1',
          description: 'This policy runs DAST for every 20 mins',
          enabled: false,
          rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *' }],
          actions: [
            { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
          ]
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#applicable_branches' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be_with_reload(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let_it_be_with_reload(:rule_schedule) do
      create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: policy_configuration)
    end

    let(:branches) { ['production'] }

    let(:policy) do
      {
        name: 'Scheduled DAST 1',
        description: 'This policy runs DAST every 20 mins',
        enabled: true,
        rules: [{ type: 'schedule', branches: branches, cadence: '*/20 * * * *' }],
        actions: [
          { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
        ]
      }
    end

    subject { rule_schedule.applicable_branches }

    before do
      allow(rule_schedule).to receive(:policy).and_return(policy)
    end

    context 'when branches does not exist' do
      let(:branches) { ['production'] }

      it { is_expected.to be_empty }
    end

    context 'when branches is empty' do
      let(:branches) { [] }

      it { is_expected.to be_empty }
    end

    context 'when some of the branches exists' do
      let(:branches) { %w[feature-a feature-b] }

      before do
        project.repository.create_branch('feature-a', project.default_branch)
        project.repository.create_branch('x-feature', project.default_branch)
      end

      it { is_expected.to eq(%w[feature-a]) }
    end

    context 'when branches with wildcards matches' do
      let(:branches) { ['feature-*'] }

      before do
        project.repository.create_branch('feature-a', project.default_branch)
        project.repository.create_branch('feature-b', project.default_branch)
        project.repository.create_branch('x-feature', project.default_branch)
      end

      it { is_expected.to eq(%w[feature-a feature-b]) }
    end

    context 'when policy is not present' do
      let(:policy) { nil }

      it { is_expected.to be_empty }
    end

    context 'when policy rules are not present' do
      before do
        policy[:rules] = []
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#set_next_run_at' do
    it_behaves_like 'handles set_next_run_at' do
      let(:schedule) { create(:security_orchestration_policy_rule_schedule, cron: '*/1 * * * *') }
      let(:schedule_1) { create(:security_orchestration_policy_rule_schedule) }
      let(:schedule_2) { create(:security_orchestration_policy_rule_schedule) }
      let(:new_cron) { '0 0 1 1 *' }

      let(:ideal_next_run_at) { schedule.send(:ideal_next_run_from, Time.zone.now) }
      let(:cron_worker_next_run_at) { schedule.send(:cron_worker_next_run_from, Time.zone.now) }
    end
  end
end
