# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'On-call Schedules (GraphQL fixtures)' do
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:project_schedule) { create(:incident_management_oncall_schedule, project: project) }

  let!(:project_rotations) do
    create_list(
      :incident_management_oncall_rotation,
        4,
        :with_participants,
        starts_at: Time.current,
        ends_at: 2.weeks.from_now,
        active_period_start: '02:00',
        active_period_end: '10:00',
        participants_count: 2,
        schedule: project_schedule,
        length: 1,
        length_unit: :weeks
    )
  end

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_member(current_user, :owner)
  end

  describe GraphQL::Query, type: :request do
    query_path = 'oncall_schedules/graphql/queries/get_oncall_schedules_with_rotations_shifts.query.graphql'

    it "graphql/#{query_path}.json" do
      query = get_graphql_query_as_string(query_path, ee: true)

      post_graphql(query, current_user: current_user, variables: {
                     projectPath: project.full_path,
                     startsAt: Time.current,
                     endsAt: 1.month.after(Time.current)
                   })

      nodes = graphql_dig_at(
        graphql_data,
        'project',
        'incidentManagementOncallSchedules',
        'nodes',
        'rotations',
        'nodes'
      )

      expect(nodes).to be_present
      expect_graphql_errors_to_be_empty
    end
  end
end
