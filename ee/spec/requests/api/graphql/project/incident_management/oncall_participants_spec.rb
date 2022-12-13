# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Incident Management on-call shifts', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:participant) { create(:incident_management_oncall_participant, :utc, :with_developer_access) }
  let_it_be(:rotation) { participant.rotation }
  let_it_be(:project) { rotation.project }
  let_it_be(:current_user) { participant.user }

  let(:fields) do
    <<~QUERY
      nodes {
        rotations {
          nodes {
            participants {
              nodes {
                id
                colorPalette
                colorWeight
                user { id }
              }
            }
          }
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('incidentManagementOncallSchedules', {}, fields)
    )
  end

  let(:participants) do
    graphql_data
      .dig('project', 'incidentManagementOncallSchedules', 'nodes').first
      .dig('rotations', 'nodes').first
      .dig('participants', 'nodes')
  end

  before do
    stub_licensed_features(oncall_schedules: true)
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns the correct properties of the on-call shifts' do
    expect(participants.first).to include(
      'id' => participant.to_global_id.to_s,
      'user' => { 'id' => participant.user.to_global_id.to_s },
      'colorWeight' => '50',
      'colorPalette' => 'blue'
    )
  end

  context 'performance' do
    shared_examples 'avoids N+1 queries' do
      specify do
        base_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        action

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(base_count)
      end
    end

    context 'for additional participant' do
      let(:action) { create(:incident_management_oncall_participant, rotation: rotation) }

      it_behaves_like 'avoids N+1 queries'
    end

    context 'for additional rotation with participants' do
      let(:action) { create(:incident_management_oncall_rotation, :with_participants, schedule: rotation.schedule) }

      it_behaves_like 'avoids N+1 queries'
    end
  end
end
