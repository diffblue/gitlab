# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Removing an escalation policy', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }

  let(:variables) { { id: escalation_policy.to_global_id.to_s } }

  let(:mutation) do
    graphql_mutation(:escalation_policy_destroy, variables) do
      <<~QL
        clientMutationId
        errors
        escalationPolicy {
          id
          name
          description
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:escalation_policy_destroy) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_maintainer(user)
  end

  it 'removes the escalation policy' do
    post_graphql_mutation(mutation, current_user: user)

    escalation_policy_response = mutation_response['escalationPolicy']

    expect(response).to have_gitlab_http_status(:success)
    expect(escalation_policy_response.slice(*%w[id name description])).to eq(
      'id' => escalation_policy.to_global_id.to_s,
      'name' => escalation_policy.name,
      'description' => escalation_policy.description
    )

    expect { escalation_policy.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
