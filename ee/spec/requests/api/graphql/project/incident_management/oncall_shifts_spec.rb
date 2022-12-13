# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Incident Management on-call shifts', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:participant) { create(:incident_management_oncall_participant, :utc, :with_developer_access) }
  let_it_be(:rotation) { participant.rotation }
  let_it_be(:project) { rotation.project }
  let_it_be(:current_user) { participant.user }

  let(:starts_at) { rotation.starts_at }
  let(:ends_at) { rotation.starts_at + rotation.shift_cycle_duration } # intentionally return one shift
  let(:params) { { start_time: starts_at.iso8601, end_time: ends_at.iso8601 } }

  let(:shift_fields) do
    <<~QUERY
      nodes {
        participant { id user { id } }
        endsAt
        startsAt
      }
    QUERY
  end

  let(:schedule_fields) do
    <<~QUERY
      nodes {
        rotations {
          nodes {
            #{query_graphql_field('shifts', params, shift_fields)}
          }
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('incidentManagementOncallSchedules', {}, schedule_fields)
    )
  end

  let(:shifts) do
    graphql_data
      .dig('project', 'incidentManagementOncallSchedules', 'nodes').first
      .dig('rotations', 'nodes').first
      .dig('shifts', 'nodes')
  end

  before do
    stub_licensed_features(oncall_schedules: true)
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns the correct properties of the on-call shifts' do
    expect(shifts.first).to include(
      'participant' => {
        'id' => participant.to_global_id.to_s,
        'user' => { 'id' => participant.user.to_global_id.to_s }
      },
      'startsAt' => params[:start_time],
      'endsAt' => params[:end_time]
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

    shared_examples 'avoids N+1 queries for additional generated shift' do
      include_examples 'avoids N+1 queries' do
        let(:action) { params[:end_time] = ends_at.next_day.iso8601 }
      end
    end

    shared_examples 'avoids N+1 queries for additional historical shift' do
      include_examples 'avoids N+1 queries' do
        let(:action) { create(:incident_management_oncall_shift, participant: participant, starts_at: last_shift.ends_at) }
      end
    end

    shared_examples 'avoids N+1 queries for additional participant' do
      include_examples 'avoids N+1 queries' do
        let(:action) { create(:incident_management_oncall_participant, rotation: rotation) }
      end
    end

    shared_examples 'avoids N+1 queries for additional rotation with participants' do
      include_examples 'avoids N+1 queries' do
        let(:action) { create(:incident_management_oncall_rotation, :with_participants, schedule: rotation.schedule) }
      end
    end

    shared_examples 'adds only one query for each additional rotation with participants' do
      specify do
        base_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        create(:incident_management_oncall_rotation, :with_participants, schedule: rotation.schedule)
        create(:incident_management_oncall_rotation, :with_participants, schedule: rotation.schedule)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(base_count).with_threshold(2)
      end
    end

    context 'for past and future shifts' do
      let_it_be(:last_shift) { create(:incident_management_oncall_shift, participant: participant) }

      let(:ends_at) { rotation.starts_at + 2 * rotation.shift_cycle_duration }

      it_behaves_like 'avoids N+1 queries for additional generated shift'
      it_behaves_like 'avoids N+1 queries for additional historical shift'
      it_behaves_like 'avoids N+1 queries for additional participant'
      it_behaves_like 'adds only one query for each additional rotation with participants'
    end

    context 'for future shifts only' do
      let(:starts_at) { rotation.starts_at + rotation.shift_cycle_duration }
      let(:ends_at) { rotation.starts_at + 2 * rotation.shift_cycle_duration }

      it_behaves_like 'avoids N+1 queries for additional generated shift'
      it_behaves_like 'avoids N+1 queries for additional participant'
      it_behaves_like 'avoids N+1 queries for additional rotation with participants'
    end

    context 'for past shifts only' do
      let_it_be(:last_shift) { create(:incident_management_oncall_shift, participant: participant) }

      around do |example|
        travel_to(starts_at + 1.5 * rotation.shift_cycle_duration) { example.run }
      end

      it_behaves_like 'avoids N+1 queries for additional historical shift'
      it_behaves_like 'avoids N+1 queries for additional participant'
      it_behaves_like 'adds only one query for each additional rotation with participants'
    end
  end

  context "without required argument starts_at" do
    let(:params) { { end_time: ends_at.iso8601 } }

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'shifts' is missing required arguments: startTime"))
    end
  end

  context "without required argument ends_at" do
    let(:params) { { start_time: starts_at.iso8601 } }

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'shifts' is missing required arguments: endTime"))
    end
  end
end
