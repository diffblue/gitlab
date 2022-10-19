# frozen_string_literal: true

class Groups::Analytics::CoverageReportsController < Groups::Analytics::ApplicationController
  feature_category :code_testing

  COVERAGE_PARAM = 'coverage'

  before_action -> { authorize_view_by_action!(:read_group_coverage_reports) }

  def index
    respond_to do |format|
      format.csv do
        ::Gitlab::Tracking.event(self.class.name, 'download_code_coverage_csv', **download_tracker_params)
        send_data(render_csv(report_results), type: 'text/csv; charset=utf-8')
      end
    end
  end

  private

  def render_csv(collection)
    CsvBuilders::SingleBatch.new(
      collection,
      {
        date: 'date',
        group_name: 'group_name',
        project_name: -> (record) { record.project.name },
        COVERAGE_PARAM => -> (record) { record.data[COVERAGE_PARAM] }
      }
    ).render
  end

  def report_results
    ::Ci::DailyBuildGroupReportResultsFinder.new(
      params: finder_params,
      current_user: current_user
    ).execute
  end

  def finder_params
    {
      group: @group,
      coverage: true,
      start_date: params[:start_date],
      end_date: params[:end_date],
      ref_path: params[:ref_path],
      sort: true
    }
  end

  def download_tracker_params
    {
      label: 'group_id',
      value: @group.id,
      user: current_user,
      namespace: @group
    }
  end
end
