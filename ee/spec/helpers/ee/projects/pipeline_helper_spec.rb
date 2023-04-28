# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelineHelper, feature_category: :pipeline_composition do
  include Ci::BuildsHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:raw_pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
  let_it_be(:pipeline) { Ci::PipelinePresenter.new(raw_pipeline, current_user: user) }

  describe '#js_pipeline_tabs_data' do
    before do
      project.add_developer(user)
    end

    subject(:pipeline_tabs_data) { helper.js_pipeline_tabs_data(project, pipeline, user) }

    it 'returns pipeline tabs data' do
      expect(pipeline_tabs_data).to include({
        can_generate_codequality_reports: pipeline.can_generate_codequality_reports?.to_json,
        can_manage_licenses: 'false',
        codequality_report_download_path: helper.codequality_report_download_path(project, pipeline),
        codequality_blob_path: codequality_blob_path(project, pipeline),
        codequality_project_path: codequality_project_path(project, pipeline),
        expose_license_scanning_data: helper.expose_license_scanning_data?(project, pipeline).to_json,
        expose_security_dashboard: pipeline.expose_security_dashboard?.to_json,
        is_full_codequality_report_available: project.licensed_feature_available?(:full_codequality_report).to_json,
        license_management_api_url: license_management_api_url(project),
        licenses_api_path: helper.licenses_api_path(project, pipeline),
        failed_jobs_count: pipeline.failed_builds.count,
        project_path: project.full_path,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        pipeline_iid: pipeline.iid,
        pipeline_path: pipeline_path(pipeline),
        pipeline_project_path: project.full_path,
        security_policies_path: kind_of(String),
        total_job_count: pipeline.total_size
      })
      expect(Gitlab::Json.parse(pipeline_tabs_data[:vulnerability_report_data])).to include({
        "empty_state_svg_path" => match_asset_path("illustrations/user-not-logged-in.svg"),
        "pipeline_id" => pipeline.id,
        "pipeline_iid" => pipeline.iid,
        "project_id" => project.id,
        "source_branch" => pipeline.source_ref,
        "pipeline_jobs_path" => "/api/v4/projects/#{project.id}/pipelines/#{pipeline.id}/jobs",
        "vulnerabilities_endpoint" => "/api/v4/projects/#{project.id}/vulnerability_findings?pipeline_id=#{pipeline.id}",
        "vulnerability_exports_endpoint" => "/api/v4/security/projects/#{project.id}/vulnerability_exports",
        "empty_state_unauthorized_svg_path" => match_asset_path("illustrations/user-not-logged-in.svg"),
        "empty_state_forbidden_svg_path" => match_asset_path("illustrations/lock_promotion.svg"),
        "project_full_path" => project.path_with_namespace,
        "commit_path_template" => "/#{project.path_with_namespace}/-/commit/$COMMIT_SHA",
        "can_admin_vulnerability" => 'false',
        "can_view_false_positive" => 'false'
      })
    end
  end

  describe 'codequality_project_path' do
    before do
      project.add_developer(user)
    end

    subject(:codequality_report_path) { helper.codequality_project_path(project, pipeline) }

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

      describe 'and there is an artefact for codequality' do
        before do
          create(:ci_build, :codequality_report, pipeline: raw_pipeline)
        end

        it 'returns the downloadable path for `codequality`' do
          is_expected.not_to be(nil)
          is_expected.to eq(project_path(project, pipeline))
        end
      end
    end
  end

  describe 'codequality_blob_path' do
    before do
      project.add_developer(user)
    end

    subject(:codequality_report_path) { helper.codequality_blob_path(project, pipeline) }

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

      describe 'and there is an artefact for codequality' do
        before do
          create(:ci_build, :codequality_report, pipeline: raw_pipeline)
        end

        it 'returns the downloadable path for `codequality`' do
          is_expected.not_to be(nil)
          is_expected.to eq(project_blob_path(project, pipeline))
        end
      end
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

  describe 'licenses_api_path' do
    before do
      project.add_developer(user)
    end

    subject(:licenses_api_path) { helper.licenses_api_path(project, pipeline) }

    describe 'when `license_scanning` feature is not available' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      it 'returns nil' do
        is_expected.to be(nil)
      end
    end

    describe 'when `license_scanning` feature is available' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      it 'returns the licenses api path' do
        is_expected.to eq(licenses_project_pipeline_path(project, pipeline))
      end
    end
  end

  describe 'license_scan_count' do
    before do
      project.add_developer(user)
    end

    subject(:license_scan_count) { helper.license_scan_count(project, pipeline) }

    describe 'when `license_scanning` feature is not available' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      it 'returns nil' do
        is_expected.to be(nil)
      end
    end

    describe 'when `license_scanning` feature is available' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      it 'returns 0' do
        is_expected.to be(0)
      end
    end
  end

  describe 'vulnerability_report_data' do
    before do
      project.add_developer(user)
    end

    subject(:vulnerability_report_data) { helper.vulnerability_report_data(project, pipeline, user) }

    it "returns the vulnerability report's data" do
      expect(vulnerability_report_data).to include({
        empty_state_svg_path: match_asset_path("illustrations/user-not-logged-in.svg"),
        pipeline_id: pipeline.id,
        pipeline_iid: pipeline.iid,
        project_id: project.id,
        source_branch: pipeline.source_ref,
        pipeline_jobs_path: "/api/v4/projects/#{project.id}/pipelines/#{pipeline.id}/jobs",
        vulnerabilities_endpoint: "/api/v4/projects/#{project.id}/vulnerability_findings?pipeline_id=#{pipeline.id}",
        vulnerability_exports_endpoint: "/api/v4/security/projects/#{project.id}/vulnerability_exports",
        empty_state_unauthorized_svg_path: match_asset_path("illustrations/user-not-logged-in.svg"),
        empty_state_forbidden_svg_path: match_asset_path("illustrations/lock_promotion.svg"),
        project_full_path: project.path_with_namespace,
        commit_path_template: "/#{project.path_with_namespace}/-/commit/$COMMIT_SHA",
        can_admin_vulnerability: 'false',
        can_view_false_positive: 'false'
      })
    end
  end
end
