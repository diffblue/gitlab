# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new on-call schedule', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:args) do
    {
      project_path: project.full_path,
      name: 'On-call rotation',
      schedule_iid: schedule.iid.to_s,
      starts_at: {
        date: "2020-09-19",
        time: "09:00"
      },
      rotation_length: {
        length: 1,
        unit: 'DAYS'
      },
      participants: [
        {
          username: current_user.username,
          colorWeight: "WEIGHT_500",
          colorPalette: "BLUE"
        }
      ]
    }
  end

  let(:mutation) do
    graphql_mutation(:oncall_rotation_create, args) do
      <<~QL
        clientMutationId
        errors
        oncallRotation {
          id
          name
          startsAt
          length
          lengthUnit
          participants {
            nodes {
              user {
                id
                username
              }
            }
          }
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:oncall_rotation_create) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(current_user)
  end

  it 'creates a new on-call rotation', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: current_user)

    new_oncall_rotation = ::IncidentManagement::OncallRotation.last!
    oncall_rotation_response = mutation_response['oncallRotation']

    expect(response).to have_gitlab_http_status(:success)

    expect(oncall_rotation_response.slice(*%w[id name length lengthUnit])).to match a_graphql_entity_for(
      new_oncall_rotation,
      'name' => args[:name],
      'length' => 1,
      'lengthUnit' => 'DAYS'
    )

    start_time = "#{args[:starts_at][:date]} #{args[:starts_at][:time]}".in_time_zone(schedule.timezone)
    expect(Time.parse(oncall_rotation_response['startsAt'])).to eq(start_time)

    expect(oncall_rotation_response.dig('participants', 'nodes')).to contain_exactly a_hash_including(
      'user' => a_graphql_entity_for(current_user, :username)
    )
  end

  %i[project_path schedule_iid name starts_at rotation_length participants].each do |argument|
    context "without required argument #{argument}" do
      before do
        args.delete(argument)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: argument
    end
  end

  context 'time is invalid' do
    before do
      args[:starts_at][:time] = '999:999'
    end

    it 'returns the on-call rotation with errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => 'Time given is invalid'))
    end
  end

  context 'date is invalid' do
    before do
      args[:starts_at][:date] = 'incorrect date'
    end

    it 'returns the on-call rotation with errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => 'Date given is invalid'))
    end
  end
end
