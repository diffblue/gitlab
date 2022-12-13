# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddNonNullConstraintForEscalationRuleOnPendingAlertEscalations, :migration, schema: 20210721174453,
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
  let!(:other_alert) { alerts.create!(iid: 2, project_id: project.id, title: 'Alert 2', started_at: Time.current) }
  let!(:other_schedule) { schedules.create!(name: 'Other Schedule', iid: 2, project_id: project.id) }

  let!(:other_project) { projects.create!(name: 'project2', path: 'project2', namespace_id: namespace.id) }
  let!(:other_project_policy) { policies.create!(name: 'Other Policy', project_id: other_project.id) }
  let!(:other_project_schedule) { schedules.create!(name: 'Other Schedule', iid: 1, project_id: other_project.id) }
  let!(:other_project_alert) { alerts.create!(iid: 1, project_id: other_project.id, title: 'Other Project Alert', started_at: Time.current) }

  let!(:policyless_project) { projects.create!(name: 'project2', path: 'project2', namespace_id: namespace.id) }
  let!(:policyless_project_schedule) { schedules.create!(name: 'Schedule for no policy', iid: 1, project_id: policyless_project.id) }
  let!(:policyless_project_alert) { alerts.create!(iid: 1, project_id: policyless_project.id, title: 'Alert with no policy', started_at: Time.current) }

  it 'creates rules for each escalation and removes escalations without policies', :aggregate_failures do
    # Should all point to the same new rule
    escalation = create_escalation
    matching_escalation = create_escalation
    other_alert_escalation = create_escalation(alert_id: other_alert.id)
    escalations_with_same_new_rule = [escalation, matching_escalation, other_alert_escalation]

    # Should each point to a different new rule
    other_status_escalation = create_escalation(status: 2)
    other_elapsed_time_escalation = create_escalation(process_at: 1.minute.from_now)
    other_schedule_escalation = create_escalation(schedule_id: other_schedule.id)
    other_project_escalation = create_escalation(schedule_id: other_project_schedule.id, alert_id: other_project_alert.id)
    escalations_with_unique_new_rules = [other_status_escalation, other_elapsed_time_escalation, other_schedule_escalation, other_project_escalation]

    # Should be deleted
    policyless_escalation = create_escalation(schedule_id: policyless_project_schedule.id, alert_id: policyless_project_alert.id)

    # Should all point to the existing rule
    existing_rule_escalation = create_escalation(rule_id: rule.id)
    existing_rule_without_schedule_escalation = create_escalation(rule_id: rule.id, status: nil, schedule_id: nil)
    existing_rule_escalation_without_rule_id = create_escalation(status: rule.status, process_at: rule.elapsed_time_seconds.seconds.after(Time.current))
    escalations_with_existing_rule = [existing_rule_escalation, existing_rule_without_schedule_escalation, existing_rule_escalation_without_rule_id]

    # Assert all escalations were updated with a rule id or deleted
    expect { migrate! }
      .to change(rules, :count).by(5)
      .and change(escalations, :count).by(-1)

    expect(escalations.pluck(:rule_id)).to all( be_present )

    escalations_with_same_new_rule.each(&:reload)
    escalations_with_unique_new_rules.each(&:reload)
    escalations_with_existing_rule.each(&:reload)

    expect { policyless_escalation.reload }.to raise_error(ActiveRecord::RecordNotFound)

    # Assert rules are associated with the correct escalations
    expect(escalations_with_existing_rule.map(&:rule_id)).to all( eq(rule.id) )
    expect(rules.where(is_removed: false)).to contain_exactly(rule)

    expect(escalations_with_same_new_rule.map(&:rule_id).uniq.length).to eq(1)

    rule_ids_for_escalations_with_unique_new_rules = escalations_with_unique_new_rules.map(&:rule_id)
    expect(rule_ids_for_escalations_with_unique_new_rules.uniq.length).to eq(rule_ids_for_escalations_with_unique_new_rules.length)
    expect(rule_ids_for_escalations_with_unique_new_rules).not_to include(escalation.rule_id, rule.id)

    # Assert new rules have the correct attributes
    escalations.where.not(rule_id: rule.id).each do |esc|
      rule = rules.find(esc.rule_id)

      expect(esc).to have_attributes(
        status: rule.status,
        schedule_id: rule.oncall_schedule_id,
        process_at: be_within(5.seconds).of(rule.elapsed_time_seconds.seconds.after(esc.created_at))
      )
    end

    # Assert all rules are associated with the correct projects
    project_rule_ids = rules.where(policy_id: policy.id).ids
    expected_rule_ids_for_project = escalations.where.not(id: other_project_escalation.id).pluck(:rule_id)
    expect(project_rule_ids - expected_rule_ids_for_project).to be_empty

    other_project_rule_ids = rules.where(policy_id: other_project_policy.id).ids
    expect(other_project_rule_ids).to contain_exactly(other_project_escalation.rule_id)

    # Assert non-null constraint was effectively applied
    expect(escalations.where(rule_id: nil)).to be_empty
    expect { create_escalation(rule_id: nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  context 'without escalations' do
    it 'adds a non-null constraint for rule_id' do
      migrate!

      expect(escalations.where(rule_id: nil)).to be_empty
      expect { create_escalation(rule_id: nil) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  private

  def create_escalation(options = {})
    escalations.create!(
      schedule_id: schedule.id,
      status: 1,
      alert_id: alert.id,
      process_at: Time.current,
      **options
    )
  end
end
