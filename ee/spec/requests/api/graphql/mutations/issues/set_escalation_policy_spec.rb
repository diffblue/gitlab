# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting the escalation policy of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:incident, project: project) }
  let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status, issue: issue) }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }
  let_it_be(:user) { create(:user) }

  let(:policy_input) { global_id_of(escalation_policy) }
  let(:input) { { project_path: project.full_path, iid: issue.iid.to_s, escalation_policy_id: policy_input } }

  let(:current_user) { user }
  let(:mutation) do
    graphql_mutation(:issue_set_escalation_policy, input) do
      <<~QL
        clientMutationId
        errors
        issue {
          iid
          escalationPolicy {
            id
            name
          }
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:issue_set_escalation_policy) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_developer(user)
  end

  context 'when user does not have permission to edit the escalation status' do
    let(:current_user) { create(:user) }

    before_all do
      project.add_reporter(user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'with non-incident issue is provided' do
    let_it_be(:issue) { create(:issue, project: project) }

    it_behaves_like 'a mutation that returns top-level errors', errors: ['Feature unavailable for provided issue']
  end

  it 'sets given escalation_policy to the escalation status for the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['issue']['escalationPolicy']).to match a_graphql_entity_for(
      escalation_policy, :name
    )
    expect(escalation_status.reload.policy).to eq(escalation_policy)
  end

  context 'when escalation_policy_id is nil' do
    let(:policy_input) { nil }

    before do
      escalation_status.update!(policy_id: escalation_policy.id, escalations_started_at: Time.current)
    end

    it 'removes existing escalation policy' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['errors']).to be_empty
      expect(escalation_status.reload.policy).to be_nil
    end
  end
end
