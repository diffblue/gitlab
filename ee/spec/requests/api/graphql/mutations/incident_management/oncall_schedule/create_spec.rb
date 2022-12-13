# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new on-call schedule', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:variables) do
    {
      project_path: project.full_path,
      name: 'New on-call schedule',
      description: 'on-call schedule description',
      timezone: 'Europe/Berlin'
    }
  end

  let(:mutation) do
    graphql_mutation(:oncall_schedule_create, variables) do
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

  let(:mutation_response) { graphql_mutation_response(:oncall_schedule_create) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(current_user)
  end

  it 'create a new on-call schedule' do
    post_graphql_mutation(mutation, current_user: current_user)

    new_oncall_schedule = ::IncidentManagement::OncallSchedule.last!
    oncall_schedule_response = mutation_response['oncallSchedule']

    expect(response).to have_gitlab_http_status(:success)
    expect(oncall_schedule_response.slice(*%w[iid name description timezone])).to eq(
      'iid' => new_oncall_schedule.iid.to_s,
      'name' => 'New on-call schedule',
      'description' => 'on-call schedule description',
      'timezone' => 'Europe/Berlin'
    )
  end

  %i[project_path name timezone].each do |argument|
    context "without required argument #{argument}" do
      before do
        variables.delete(argument)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: argument
    end
  end
end
