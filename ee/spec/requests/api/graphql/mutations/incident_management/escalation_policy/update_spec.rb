# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an escalation policy', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }
  let_it_be(:schedule) { escalation_policy.rules.first.oncall_schedule }

  let(:variables) do
    {
      id: escalation_policy.to_global_id.to_s,
      name: 'Updated Policy Name',
      description: 'Updated Description',
      rules: [rule_variables]
    }
  end

  let(:rule_variables) do
    {
      oncallScheduleIid: schedule.iid,
      elapsedTimeSeconds: 60,
      status: 'ACKNOWLEDGED'
    }
  end

  let(:mutation) do
    graphql_mutation(:escalation_policy_update, variables) do
      <<~QL
        errors
        escalationPolicy {
          id
          name
          description
          rules {
            status
            elapsedTimeSeconds
            oncallSchedule { iid }
          }
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:escalation_policy_update) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_maintainer(user)
  end

  it 'updates the escalation policy' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)

    expect(mutation_response).to eq(
      'errors' => [],
      'escalationPolicy' => {
        'id' => escalation_policy.to_global_id.to_s,
        'name' => variables[:name],
        'description' => variables[:description],
        'rules' => [{
          'status' => rule_variables[:status],
          'elapsedTimeSeconds' => rule_variables[:elapsedTimeSeconds],
          'oncallSchedule' => { 'iid' => schedule.iid.to_s }
        }]
      }
    )

    expect(escalation_policy.reload).to have_attributes(
      name: variables[:name],
      description: variables[:description],
      active_rules: [
        have_attributes(
          oncall_schedule: schedule,
          status: rule_variables[:status].downcase,
          elapsed_time_seconds: rule_variables[:elapsedTimeSeconds]
        )
      ]
    )
  end

  include_examples 'correctly reorders escalation rule inputs' do
    let(:resolve) { post_graphql_mutation(mutation, current_user: user) }
  end
end
