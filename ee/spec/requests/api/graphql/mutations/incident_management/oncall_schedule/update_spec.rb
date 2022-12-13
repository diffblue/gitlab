# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an on-call schedule', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:variables) do
    {
      project_path: project.full_path,
      iid: oncall_schedule.iid.to_s,
      name: 'Updated name',
      description: 'Updated description',
      timezone: 'America/New_York'
    }
  end

  let(:mutation) do
    graphql_mutation(:oncall_schedule_update, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:oncall_schedule_update) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(user)
  end

  it 'updates the on-call schedule' do
    post_graphql_mutation(mutation, current_user: user)

    oncall_schedule_response = mutation_response['oncallSchedule']

    expect(response).to have_gitlab_http_status(:success)
    expect(oncall_schedule_response.slice(*%w[iid name description timezone])).to eq(
      'iid' => oncall_schedule.iid.to_s,
      'name' => variables[:name],
      'description' => variables[:description],
      'timezone' => variables[:timezone]
    )
  end
end
