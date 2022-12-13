# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Removing an on-call schedule', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:variables) { { project_path: project.full_path, iid: oncall_schedule.iid.to_s } }

  let(:mutation) do
    graphql_mutation(:oncall_schedule_destroy, variables) do
      <<~QL
        clientMutationId
        errors
        oncallSchedule {
          iid
          name
          description
          timezone
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:oncall_schedule_destroy) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(user)
  end

  it 'removes the on-call schedule' do
    post_graphql_mutation(mutation, current_user: user)

    oncall_schedule_response = mutation_response['oncallSchedule']

    expect(response).to have_gitlab_http_status(:success)
    expect(oncall_schedule_response.slice(*%w[iid name description timezone])).to eq(
      'iid' => oncall_schedule.iid.to_s,
      'name' => oncall_schedule.name,
      'description' => oncall_schedule.description,
      'timezone' => oncall_schedule.timezone
    )

    expect { oncall_schedule.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
