# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Incident Management escalation policies', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }
  let_it_be(:rule) { policy.rules.first }
  let_it_be(:schedule) { rule.oncall_schedule }
  let_it_be(:user_rule) { create(:incident_management_escalation_rule, :with_user, policy: policy) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        id
        rules {
          id
          elapsedTimeSeconds
          status
          oncallSchedule {
            iid
            name
          }
          user {
            username
          }
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('incidentManagementEscalationPolicies', {}, fields)
    )
  end

  let(:escalation_policy_response) { graphql_data.dig('project', 'incidentManagementEscalationPolicies', 'nodes').first }
  let(:escalation_rules_response) { escalation_policy_response['rules'] }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_reporter(current_user)
  end

  it 'includes expected data' do
    post_graphql(query, current_user: current_user)

    expect(escalation_rules_response).to eq(
      [
        {
          'id' => global_id(rule),
          'elapsedTimeSeconds' => rule.elapsed_time_seconds, # 5 min
          'status' => rule.status.upcase, # 'ACKNOWLEDGED'
          'oncallSchedule' => {
            'iid' => schedule.iid.to_s,
            'name' => schedule.name
          },
          'user' => nil
        },
        {
          'id' => global_id(user_rule),
          'elapsedTimeSeconds' => user_rule.elapsed_time_seconds, # 5 min
          'status' => user_rule.status.upcase, # 'ACKNOWLEDGED'
          'oncallSchedule' => nil,
          'user' => { 'username' => user_rule.user.username }
        }
      ])
  end

  context 'with multiple rules' do
    let_it_be(:later_acknowledged_rule) { create(:incident_management_escalation_rule, policy: policy, elapsed_time_seconds: 10.minutes) }
    let_it_be(:earlier_resolved_rule) { create(:incident_management_escalation_rule, :resolved, policy: policy, elapsed_time_seconds: 1.minute) }
    let_it_be(:equivalent_resolved_rule) { create(:incident_management_escalation_rule, :resolved, policy: policy) }

    it 'orders rules by time and status' do
      post_graphql(query, current_user: current_user)

      expect(escalation_rules_response.length).to eq(5)
      expect(escalation_rules_response.map { |rule| rule['id'] }).to eq(
        [
          global_id(earlier_resolved_rule),
          global_id(rule),
          global_id(user_rule),
          global_id(equivalent_resolved_rule),
          global_id(later_acknowledged_rule)
        ])
    end
  end

  it 'avoids N+1 queries' do
    post_graphql(query, current_user: current_user)

    base_count = ActiveRecord::QueryRecorder.new do
      post_graphql(query, current_user: current_user)
    end

    create(:incident_management_escalation_rule, policy: policy, elapsed_time_seconds: 1.hour)

    expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(base_count)
  end

  private

  def global_id(object)
    object.to_global_id.to_s
  end
end
