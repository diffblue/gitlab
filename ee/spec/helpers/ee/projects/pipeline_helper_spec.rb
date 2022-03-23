# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelineHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:raw_pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
  let_it_be(:pipeline) { Ci::PipelinePresenter.new(raw_pipeline, current_user: user)}

  describe '#js_pipeline_tabs_data' do
    subject(:pipeline_tabs_data) { helper.js_pipeline_tabs_data(project, pipeline) }

    it 'returns pipeline tabs data' do
      expect(pipeline_tabs_data).to eq({
        can_generate_codequality_reports: pipeline.can_generate_codequality_reports?.to_json,
        codequality_report_download_path: helper.codequality_report_download_path(project, pipeline),
        expose_license_scanning_data: pipeline.expose_license_scanning_data?.to_json,
        expose_security_dashboard: pipeline.expose_security_dashboard?.to_json,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        pipeline_project_path: project.full_path
      })
    end
  end

  describe 'codequality_report_download_path' do
    before do
      project.add_developer(user)
    end

    subject(:codequality_report_path) { helper.codequality_report_download_path(project, pipeline) }

    describe 'when `full_codequality_report` feature is not available' do
      before do
        stub_licensed_features(full_codequality_report: false)
      end

      it 'returns nil' do
        is_expected.to be(nil)
      end
    end

    describe 'when `full_code_quality_report` feature is available' do
      before do
        stub_licensed_features(full_codequality_report: true)
      end

      describe 'and there is no artefact for codequality' do
        it 'returns nil for `codequality`' do
          is_expected.to be(nil)
        end
      end

      describe 'and there is an artefact for codequality' do
        before do
          create(:ci_build, :codequality_report, pipeline: raw_pipeline)
        end

        it 'returns the downloadable path for `codequality`' do
          is_expected.not_to be(nil)
          is_expected.to eq(pipeline.downloadable_path_for_report_type(:codequality))
        end
      end
    end
  end
end
