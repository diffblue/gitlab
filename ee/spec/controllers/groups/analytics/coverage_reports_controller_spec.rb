# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CoverageReportsController, feature_category: :team_planning do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:ref_path) { 'refs/heads/master' }

  let_it_be(:first_coverage) { create_daily_coverage('rspec', project, 79.0, '2020-03-09', group) }
  let_it_be(:last_coverage) { create_daily_coverage('karma', project, 95.0, '2020-03-10', group) }

  let_it_be(:valid_request_params) do
    {
      group_id: group.name,
      start_date: '2020-03-01',
      end_date: '2020-03-31',
      ref_path: ref_path,
      format: :csv
    }
  end

  before do
    sign_in(user)
  end

  context 'without permissions' do
    before do
      group.add_guest(user)
    end

    describe 'GET index' do
      it 'responds 403' do
        get :index, params: valid_request_params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'with permissions' do
    before do
      group.add_reporter(user)
    end

    context 'without a license' do
      before do
        stub_licensed_features(group_coverage_reports: false)
      end

      describe 'GET index' do
        it 'responds 403 because the feature is not licensed' do
          get :index, params: valid_request_params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    describe 'GET index' do
      before do
        stub_licensed_features(group_coverage_reports: true)
      end

      it 'responds 200 with CSV coverage data', :snowplow do
        get :index, params: valid_request_params

        expect_snowplow_event(
          category: described_class.name,
          action: 'download_code_coverage_csv',
          label: 'group_id',
          value: group.id,
          user: user,
          namespace: group
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(csv_response).to eq(
          [
            %w[date group_name project_name coverage],
            [last_coverage.date.to_s, last_coverage.group_name, project.name, last_coverage.data['coverage'].to_s],
            [first_coverage.date.to_s, first_coverage.group_name, project.name, first_coverage.data['coverage'].to_s]
          ])
      end

      context 'when ref_path is nil' do
        let(:ref_path) { nil }

        it 'responds HTTP 200' do
          get :index, params: valid_request_params

          expect(response).to have_gitlab_http_status(:ok)
          expect(csv_response.size).to eq(3)
        end
      end

      it 'executes the same number of queries regardless of the number of records returned' do
        control = ActiveRecord::QueryRecorder.new do
          get :index, params: valid_request_params
        end

        expect(CSV.parse(response.body).length).to eq(3)

        create_daily_coverage('rspec', project, 79.0, '2020-03-10', group)

        expect { get :index, params: valid_request_params }.not_to exceed_query_limit(control)

        expect(csv_response.length).to eq(4)
      end

      context 'with an invalid format' do
        it 'responds 404' do
          get :index, params: valid_request_params.merge(format: :json)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  private

  def create_daily_coverage(group_name, project, coverage, date, group = nil)
    create(
      :ci_daily_build_group_report_result,
      project: project,
      ref_path: ref_path,
      group_name: group_name,
      data: { 'coverage' => coverage },
      date: date,
      group: group
    )
  end
end
