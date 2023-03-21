# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SyncSecurityPolicyRuleSchedulesThatMayHaveBeenDeletedByABug, feature_category: :security_policy_management do
  let(:migration) { described_class.new }

  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }
  let(:security_orchestration_policy_rule_schedules) { table(:security_orchestration_policy_rule_schedules) }

  let(:user) { users.create!(name: 'Example User', email: 'user@example.com', projects_limit: 0) }
  let(:namespace_1) { namespaces.create!(name: '1', path: '1') }
  let(:namespace_2) { namespaces.create!(name: '2', path: '2') }
  let(:namespace_3) { namespaces.create!(name: '3', path: '3') }
  let(:project_1) { projects.create!(namespace_id: namespace_1.id, project_namespace_id: namespace_1.id) }
  let(:project_2) { projects.create!(namespace_id: namespace_2.id, project_namespace_id: namespace_2.id) }
  let(:project_3) { projects.create!(namespace_id: namespace_3.id, project_namespace_id: namespace_3.id) }
  let(:policy_configuration_1) { create_policy_configuration(project_id: project_1.id) }
  let(:policy_configuration_2) { create_policy_configuration(project_id: project_2.id) }
  let(:policy_configuration_3) { create_policy_configuration(project_id: project_3.id) }

  describe '#up' do
    before do
      # Not impacted by bug
      create_rule_schedule(configuration_id: policy_configuration_1.id, policy_index: 0, rule_index: 0)

      # Impacted by bug
      create_rule_schedule(configuration_id: policy_configuration_2.id, policy_index: 1, rule_index: 0)
      create_rule_schedule(configuration_id: policy_configuration_3.id, policy_index: 2, rule_index: 0)
      create_rule_schedule(configuration_id: policy_configuration_3.id, policy_index: 2, rule_index: 1)
    end

    it 'bulk enqueues one SyncScanPoliciesWorker for each unique policy configuration id' do
      expect(Security::SyncScanPoliciesWorker).to receive(:bulk_perform_async) do |args|
        expect(args.length).to eq(2)
        expect(args).to contain_exactly([policy_configuration_2.id], [policy_configuration_3.id])
      end

      migrate!
    end
  end

  def create_policy_configuration(project_id:)
    security_orchestration_policy_configurations.create!(
      project_id: project_id,
      security_policy_management_project_id: project_id
    )
  end

  def create_rule_schedule(configuration_id:, policy_index:, rule_index:, user_id: user.id, cron: '*/15 * * * *')
    security_orchestration_policy_rule_schedules.create!(
      security_orchestration_policy_configuration_id: configuration_id,
      user_id: user_id,
      cron: cron,
      policy_index: policy_index,
      rule_index: rule_index
    )
  end
end
