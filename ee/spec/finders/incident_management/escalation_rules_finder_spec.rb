# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationRulesFinder do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }
  let_it_be(:other_policy) { create(:incident_management_escalation_policy, project: other_project) }

  let_it_be(:schedule_rule) { policy.rules.first }
  let_it_be(:schedule_rule_for_other_project) { other_policy.rules.first }
  let_it_be(:removed_rule) { create(:incident_management_escalation_rule, :removed, policy: policy) }

  let_it_be(:rule_for_user) { create(:incident_management_escalation_rule, :with_user, policy: policy, user: user) }
  let_it_be(:rule_for_other_user) { create(:incident_management_escalation_rule, :with_user, policy: policy) }
  let_it_be(:rule_for_other_policy) { create(:incident_management_escalation_rule, :with_user, policy: other_policy, user: user) }

  let_it_be(:project_member) { project.members.first }
  let_it_be(:group_member) { create(:group_member, :developer, group: group, user: user) }

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(**params).execute }

    context 'when project is given' do
      let(:project_rules) { [rule_for_user, rule_for_other_user, schedule_rule] }

      it 'returns the rules in the project for different types of project inputs' do
        [
          project,
          project.id,
          [project],
          [project.id],
          Project.where(id: project.id)
        ].each do |project_param|
          expect(described_class.new(project: project_param).execute).to contain_exactly(*project_rules)
        end
      end

      context 'when removed rules should be included' do
        let(:params) { { include_removed: true, project: project } }

        it { is_expected.to contain_exactly(removed_rule, *project_rules) }
      end
    end

    context 'when user is given' do
      it 'returns the user rules for different types of user inputs' do
        [
          user,
          user.id,
          [user],
          [user.id],
          User.where(id: user.id)
        ].each do |user_param|
          expect(described_class.new(user: user_param).execute).to contain_exactly(
            rule_for_user,
            rule_for_other_policy
          )
        end
      end
    end

    context 'when group member is given' do
      let(:params) { { member: group_member } }

      it { is_expected.to contain_exactly(rule_for_user, rule_for_other_policy) }

      context 'when member does not belong to a user' do
        let(:params) { { member: create(:group_member, :invited, group: group) } }

        specify { expect { execute }.to raise_error(ArgumentError, 'Member does not correspond to a user') }
      end
    end

    context 'when project member is given' do
      let(:params) { { member: project_member } }

      it { is_expected.to contain_exactly(rule_for_other_user) }

      context 'when user is also given' do
        let(:params) { { member: project_member, user: user } }

        specify { expect { execute }.to raise_error(ArgumentError, 'Member param cannot be used with project or user params') }
      end

      context 'when project is also given' do
        let(:params) { { member: project_member, project: project } }

        specify { expect { execute }.to raise_error(ArgumentError, 'Member param cannot be used with project or user params') }
      end
    end
  end
end
