# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicies::UpdateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }

  let_it_be_with_reload(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }
  let_it_be_with_reload(:schedule_escalation_rule) { escalation_policy.rules.first }
  let_it_be_with_reload(:user_escalation_rule) { create(:incident_management_escalation_rule, :with_user, policy: escalation_policy) }
  let_it_be_with_reload(:escalation_rules) { escalation_policy.reload.rules }

  let(:service) { described_class.new(escalation_policy, current_user, params) }
  let(:current_user) { user_with_permissions }

  let(:params) do
    {
      name: 'Updated escalation policy name',
      description: 'Updated escalation policy description',
      rules_attributes: rule_params
    }
  end

  let(:rule_params) { [*existing_rules_params, new_rule_params] }
  let(:existing_rules_params) do
    escalation_rules.map do |rule|
      rule.slice(:oncall_schedule, :user, :elapsed_time_seconds)
          .merge(status: rule.status.to_sym)
    end
  end

  let(:user_for_rule) {}
  let(:new_rule_params) do
    {
      oncall_schedule: oncall_schedule,
      user: user_for_rule,
      elapsed_time_seconds: 800,
      status: :acknowledged
    }
  end

  let(:new_rule) { have_attributes(**new_rule_params.except(:status), status: 'acknowledged') }
  let(:removed_rules) { [] }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  before_all do
    project.add_maintainer(user_with_permissions)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    # Requires `expected_rules` to be defined
    shared_examples 'successful update with no errors' do
      it 'returns the updated escalation policy' do
        expect(execute).to be_success

        expect(execute.payload).to eq(escalation_policy: escalation_policy.reload)
        expect(escalation_policy).to have_attributes(params.slice(:name, :description))
        expect(escalation_policy.active_rules).to match_array(expected_rules)
        expect(escalation_policy.rules.removed).to match_array(removed_rules)
      end
    end

    subject(:execute) { service.execute }

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when the current_user does not have permissions to update escalation policies' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when license is not enabled' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: false)
      end

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when only new rules are added' do
      let(:expected_rules) { [*escalation_rules, new_rule] }

      it_behaves_like 'successful update with no errors'

      context 'with a user-based rule' do
        let(:oncall_schedule) { nil }
        let(:user_for_rule) { user_with_permissions }

        it_behaves_like 'successful update with no errors'
      end
    end

    context 'when all old rules are replaced' do
      let(:rule_params) { [new_rule_params] }
      let(:expected_rules) { [new_rule] }
      let(:removed_rules) { escalation_rules }

      it_behaves_like 'successful update with no errors'
    end

    context 'when some rules are preserved, added, and deleted' do
      let(:rule_params) { [existing_rules_params.first, new_rule_params] }
      let(:expected_rules) { [escalation_rules.first, new_rule] }
      let(:removed_rules) { [escalation_rules.last] }

      it_behaves_like 'successful update with no errors'
    end

    context 'when rules are only deleted' do
      let(:rule_params) { [existing_rules_params.first] }
      let(:expected_rules) { [escalation_rules.first] }
      let(:removed_rules) { [escalation_rules.last] }

      it_behaves_like 'successful update with no errors'
    end

    context 'when rules are unchanged' do
      let(:rule_params) { existing_rules_params }
      let(:expected_rules) { escalation_rules }

      it_behaves_like 'successful update with no errors'
    end

    context 'when rules are excluded' do
      let(:expected_rules) { escalation_rules }

      before do
        params.delete(:rules_attributes)
      end

      it_behaves_like 'successful update with no errors'
    end

    context 'when rules are explicitly nil' do
      let(:rule_params) { nil }
      let(:expected_rules) { escalation_rules }

      it_behaves_like 'successful update with no errors'
    end

    context 'when rules are explicitly empty' do
      let(:rule_params) { [] }
      let(:expected_rules) { escalation_rules }

      it_behaves_like 'error response', 'Escalation policies must have at least one rule'
    end

    context 'when too many rules are given' do
      let(:rule_params) { [*existing_rules_params, *new_rule_params] }
      let(:new_rule_params) do
        (0..9).map do |idx|
          {
            oncall_schedule: oncall_schedule,
            elapsed_time_seconds: idx,
            status: :acknowledged
          }
        end
      end

      it_behaves_like 'error response', 'Escalation policies may not have more than 10 rules'
    end

    context 'when the on-call schedule is not on the project' do
      let(:other_schedule) { create(:incident_management_oncall_schedule) }
      let(:rule_params) { [new_rule_params.merge(oncall_schedule: other_schedule)] }

      it_behaves_like 'error response', 'Schedule-based escalation rules must have a schedule in the same project as the policy'
    end

    context "when the rule's user does not have access to the project" do
      let(:oncall_schedule) { nil }
      let(:user_for_rule) { user_without_permissions }

      it_behaves_like 'error response', 'User-based escalation rules must have a user with access to the project'
    end

    context 'when an error occurs during update' do
      before do
        params[:name] = ''
      end

      it_behaves_like 'error response', "Name can't be blank"
    end
  end
end
