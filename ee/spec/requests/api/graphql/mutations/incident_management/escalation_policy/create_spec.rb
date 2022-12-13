# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'creating escalation policy', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:params) { create_params }

  let(:mutation) do
    graphql_mutation(:escalation_policy_create, params) do
      <<-QL.strip_heredoc
        escalationPolicy {
          id
          name
          description
          rules {
            status
            elapsedTimeSeconds
            oncallSchedule {
              name
              iid
            }
          }
        }
        errors
      QL
    end
  end

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_maintainer(current_user)
  end

  subject(:resolve) { post_graphql_mutation(mutation, current_user: current_user) }

  it 'successfully creates the policy and rules' do
    resolve

    expect(mutation_response['errors']).to be_empty

    escalation_policy_response = mutation_response['escalationPolicy']
    expect(escalation_policy_response['name']).to eq(create_params[:name])
    expect(escalation_policy_response['description']).to eq(create_params[:description])
    expect(escalation_policy_response['rules'].size).to eq(create_params[:rules].size)

    first_rule = escalation_policy_response['rules'].first
    expect(first_rule['status']).to eq('ACKNOWLEDGED')
    expect(first_rule['elapsedTimeSeconds']).to eq(create_params.dig(:rules, 0, :elapsedTimeSeconds))
    expect(first_rule['status']).to eq(create_params.dig(:rules, 0, :status))
  end

  include_examples 'correctly reorders escalation rule inputs' do
    let(:variables) { params }
  end

  context 'errors' do
    context 'user does not have permission' do
      subject(:resolve) { post_graphql_mutation(mutation, current_user: create(:user)) }

      it 'raises an error' do
        resolve

        expect_graphql_errors_to_include(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'no rules given' do
      before do
        params[:rules] = []
      end

      it 'raises an error' do
        resolve

        expect(mutation_response['errors'][0]).to eq('Escalation policies must have at least one rule')
      end
    end
  end

  def mutation_response
    graphql_mutation_response(:escalation_policy_create)
  end

  def create_params
    {
      projectPath: project.full_path,
      name: 'Escalation Policy 1',
      description: 'Description',
      rules: [
        {
          oncallScheduleIid: schedule.iid,
          elapsedTimeSeconds: 60,
          status: 'ACKNOWLEDGED'
        }
      ]
    }
  end
end
