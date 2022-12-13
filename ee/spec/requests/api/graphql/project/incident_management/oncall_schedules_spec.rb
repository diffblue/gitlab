# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Incident Management on-call schedules', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('IncidentManagementOncallSchedule')}
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

  let(:oncall_schedules) { graphql_data.dig('project', 'incidentManagementOncallSchedules', 'nodes') }

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  context 'without project permissions' do
    let(:user) { create(:user) }

    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it { expect(oncall_schedules).to be_nil }
  end

  context 'with project permissions' do
    before do
      project.add_maintainer(current_user)
    end

    context 'with unavailable feature' do
      before do
        stub_licensed_features(oncall_schedules: false)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it { expect(oncall_schedules).to be_empty }
    end

    context 'without on-call schedules' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it { expect(oncall_schedules).to be_empty }
    end

    context 'with on-call schedules' do
      let!(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }
      let(:first_oncall_schedule) { oncall_schedules.first }
      let(:last_oncall_schedule) { oncall_schedules.last }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns the correct properties of the on-call schedule' do
        expect(last_oncall_schedule).to include(
          'iid' => oncall_schedule.iid.to_s,
          'name' => oncall_schedule.name,
          'description' => oncall_schedule.description,
          'timezone' => oncall_schedule.timezone
        )
      end

      context 'with an array of iids given' do
        let(:params) { { iids: [oncall_schedule.iid.to_s] } }

        it_behaves_like 'a working graphql query'

        it { expect(oncall_schedules.size).to eq(1) }
        it { expect(first_oncall_schedule['iid']).to eq(oncall_schedule.iid.to_s) }
      end
    end
  end
end
