# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberUserEntity do
  include OncallHelpers

  let_it_be_with_reload(:user) { create(:user) }

  let(:entity) { described_class.new(user, source: source) }
  let(:entity_hash) { entity.as_json }
  let(:source) { nil }

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('entities/member_user_default')
  end

  context 'when using on-call management' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project_1) { create(:project, group: group ) }
    let_it_be(:project_2) { create(:project, group: group ) }

    context 'with oncall schedules' do
      let_it_be(:oncall_schedule_1) { create_schedule_with_user(project_1, user) }
      let_it_be(:oncall_schedule_2) { create_schedule_with_user(project_2, user) }

      subject { entity_hash[:oncall_schedules] }

      context 'with no source given' do
        it { is_expected.to eq [] }
      end

      context 'source is project' do
        let(:source) { project_1 }

        it { is_expected.to contain_exactly(expected_hash(oncall_schedule_1)) }
      end

      context 'source is group' do
        let(:source) { group }

        it { is_expected.to contain_exactly(expected_hash(oncall_schedule_1), expected_hash(oncall_schedule_2)) }
      end

      private

      def get_url(schedule)
        Gitlab::Routing.url_helpers.project_incident_management_oncall_schedules_url(schedule.project)
      end

      def expected_hash(schedule)
        # for backwards compatibility
        super.merge(schedule_url: get_url(schedule))
      end
    end

    context 'with escalation policies' do
      let_it_be(:policy_1) { create(:incident_management_escalation_policy, project: project_1, rule_count: 0) }
      let_it_be(:rule_1) { create(:incident_management_escalation_rule, :with_user, policy: policy_1, user: user) }
      let_it_be(:policy_2) { create(:incident_management_escalation_policy, project: project_2, rule_count: 0) }
      let_it_be(:rule_2) { create(:incident_management_escalation_rule, :with_user, policy: policy_2, user: user) }

      subject { entity_hash[:escalation_policies] }

      context 'with no source given' do
        it { is_expected.to eq [] }
      end

      context 'source is project' do
        let(:source) { project_1 }

        it { is_expected.to contain_exactly(expected_hash(policy_1)) }
      end

      context 'source is group' do
        let(:source) { group }

        it { is_expected.to contain_exactly(expected_hash(policy_1), expected_hash(policy_2)) }
      end

      private

      def get_url(policy)
        Gitlab::Routing.url_helpers.project_incident_management_escalation_policies_url(policy.project)
      end
    end

    private

    def expected_hash(oncall_object)
      {
        name: oncall_object.name,
        url: get_url(oncall_object),
        project_name: oncall_object.project.name,
        project_url: Gitlab::Routing.url_helpers.project_url(oncall_object.project)
      }
    end
  end
end
