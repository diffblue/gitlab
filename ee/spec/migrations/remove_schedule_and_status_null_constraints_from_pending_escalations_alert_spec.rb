# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveScheduleAndStatusNullConstraintsFromPendingEscalationsAlert, :migration, schema: 20210721174441,
                                                                                              feature_category: :incident_management do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:schedules) { table(:incident_management_oncall_schedules) }
  let(:policies) { table(:incident_management_escalation_policies) }
  let(:rules) { table(:incident_management_escalation_rules) }
  let(:alerts) { table(:alert_management_alerts) }
  let(:escalations) { partitioned_table(:incident_management_pending_alert_escalations, by: :process_at) }

  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project) { projects.create!(name: 'project', path: 'project', namespace_id: namespace.id) }
  let!(:schedule) { schedules.create!(name: 'Schedule', iid: 1, project_id: project.id) }
  let!(:policy) { policies.create!(name: 'Policy', project_id: project.id) }
  let!(:rule) { rules.create!(oncall_schedule_id: schedule.id, policy_id: policy.id, status: 2, elapsed_time_seconds: 5.minutes) }
  let!(:alert) { alerts.create!(iid: 1, project_id: project.id, title: 'Alert 1', started_at: Time.current) }

  let!(:other_schedule) { schedules.create!(name: 'Other Schedule', iid: 2, project_id: project.id) }
  let!(:other_rule) { rules.create!(oncall_schedule_id: other_schedule.id, policy_id: policy.id, status: 2, elapsed_time_seconds: 5.minutes) }
  let!(:other_alert) { alerts.create!(iid: 2, project_id: project.id, title: 'Alert 2', started_at: Time.current) }

  let(:rule_only_escalation) { create_escalation }
  let(:duplicate_escalation) { create_escalation }
  let(:other_rule_escalation) { create_escalation(rule_id: other_rule.id) }
  let(:other_alert_escalation) { create_escalation(alert_id: other_alert.id) }
  let(:all_escalations) { [rule_only_escalation, duplicate_escalation, other_rule_escalation, other_alert_escalation] }

  it 'reversibly removes the non-null constraint for schedule_id and status', :aggregate_failures do
    reversible_migration do |migration|
      migration.before -> {
        expect { create_escalation(status: rule.status, schedule_id: rule.oncall_schedule_id) }.not_to raise_error
        expect { create_escalation }.to raise_error(ActiveRecord::NotNullViolation)

        escalations.all.each do |escalation|
          rule = rules.find(escalation.rule_id)
          expect(escalation).to have_attributes(schedule_id: rule.oncall_schedule_id, status: rule.status)
        end
      }

      migration.after -> {
        expect { all_escalations }.not_to raise_error
      }
    end
  end

  context 'without escalations' do
    it 'removes the non-null constraint for schedule_id and status' do
      migrate!

      expect { create_escalation(status: 1) }.not_to raise_error
      expect { create_escalation(schedule_id: schedule.id) }.not_to raise_error
    end
  end

  private

  def create_escalation(options = {})
    escalations.create!(
      rule_id: rule.id,
      alert_id: alert.id,
      process_at: Time.current,
      **options
    )
  end
end
