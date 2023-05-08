# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::StagesController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:namespace) { project.project_namespace }

  let_it_be(:stages) do
    [
      create(:cycle_analytics_stage, namespace: namespace, name: "Issue", relative_position: 1),
      create(:cycle_analytics_stage, namespace: namespace, name: "Code", relative_position: 2)
    ]
  end

  let_it_be(:value_stream) do
    create(
      :cycle_analytics_value_stream,
      namespace: namespace,
      name: 'First value stream',
      stages: stages
    )
  end

  let(:params) do
    { namespace_id: project.namespace.to_param, project_id: project.to_param, value_stream_id: value_stream.id }
  end

  before do
    stub_licensed_features(cycle_analytics_for_projects: true)
    project.add_reporter(user)
    login_as(user)
  end

  shared_examples 'licensed project-level value stream stages examples' do
    it 'fails when stage is not found' do
      params[:id] = non_existing_record_id

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'fails when license is missing' do
      stub_licensed_features(cycle_analytics_for_projects: false)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET #index' do
    subject { get namespace_project_analytics_cycle_analytics_value_stream_stages_path(params) }

    it 'succeeds' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('analytics/cycle_analytics/stages', dir: 'ee')
    end

    context 'when the project is not licensed' do
      before do
        stub_licensed_features(cycle_analytics_for_projects: false)
      end

      it 'returns forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'when requesting aggregation endpoints' do
    before do
      params[:id] = stages.first.id
    end

    describe 'GET #median' do
      subject { get median_namespace_project_analytics_cycle_analytics_value_stream_stage_path(params) }

      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('analytics/cycle_analytics/number_or_nil_value', dir: 'ee')
      end

      it_behaves_like 'licensed project-level value stream stages examples'
    end

    describe 'GET #average' do
      subject { get average_namespace_project_analytics_cycle_analytics_value_stream_stage_path(params) }

      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('analytics/cycle_analytics/number_or_nil_value', dir: 'ee')
      end

      it_behaves_like 'licensed project-level value stream stages examples'
    end

    describe 'GET #records' do
      subject { get records_namespace_project_analytics_cycle_analytics_value_stream_stage_path(params) }

      it 'succeeds' do
        subject

        expect(json_response).to eq([])
        expect(response).to have_gitlab_http_status(:ok)
      end

      it_behaves_like 'licensed project-level value stream stages examples'
    end

    describe 'GET #count' do
      subject { get count_namespace_project_analytics_cycle_analytics_value_stream_stage_path(params) }

      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['count']).to eq(0)
      end

      it_behaves_like 'licensed project-level value stream stages examples'
    end

    describe 'GET #average_duration_chart' do
      subject { get namespace_project_analytics_cycle_analytics_average_duration_chart_path(params) }

      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('analytics/cycle_analytics/average_duration_chart', dir: 'ee')
      end

      it_behaves_like 'licensed project-level value stream stages examples'
    end
  end
end
