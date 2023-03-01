# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ScannedResourcesController, type: :request, feature_category: :dynamic_application_security_testing do
  describe 'GET #index' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
    let_it_be(:pipeline_without_scan) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline_on_another_project) { create(:ci_pipeline) }
    let_it_be(:pipeline_id) { pipeline.id }

    let(:parsed_csv_data) { CSV.parse(response.body, headers: true) }

    subject(:request) { get project_security_scanned_resources_path(project, :csv, pipeline_id: pipeline_id) }

    before do
      stub_licensed_features(dast: true, security_dashboard: true)

      login_as(user)
    end

    include_context '"Security and Compliance" permissions' do
      let(:valid_request) { request }

      before_request do
        project.add_developer(user)
      end
    end

    shared_examples 'returns a 404' do
      it 'will return a 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'user has access to view vulnerabilities' do
      before do
        project.add_developer(user)
      end

      context 'when DAST security scan is found' do
        before do
          create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
            create(:ee_ci_job_artifact, :dast, job: job, project: project)
          end
        end

        it 'returns a CSV representation of the scanned resources' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(parsed_csv_data.length).to eq(6)
          expect(parsed_csv_data.first.to_h).to include(
            'Method' => 'GET',
            'Scheme' => 'http',
            'Host' => 'api-server',
            'Port' => '80',
            'Path' => '/',
            'Query String' => nil
          )
        end
      end

      context 'when DAST licensed feature is unavailable' do
        before do
          stub_licensed_features(dast: false)
        end

        include_examples 'returns a 404'
      end

      context 'when security_dashboard licensed feature is not available' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        include_examples 'returns a 404'
      end

      context 'when DAST security scan is not found' do
        let(:pipeline_id) { pipeline_without_scan.id }

        include_examples 'returns a 404'
      end

      context 'when the pipeline id exists under another project' do
        let(:pipeline_id) { pipeline_on_another_project.id }

        before do
          create(:ci_build, :success, name: 'dast_job', pipeline: pipeline_on_another_project, project: pipeline_on_another_project.project) do |job|
            create(:ee_ci_job_artifact, :dast, job: job, project: pipeline_on_another_project.project)
          end
        end

        include_examples 'returns a 404'
      end

      context 'when the pipeline does not exist' do
        let(:pipeline_id) { 'not_a_valid_id' }

        include_examples 'returns a 404'
      end
    end

    context 'user does not have access to view vulnerabilities' do
      before do
        project.add_guest(user)
        create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
          create(:ee_ci_job_artifact, :dast, job: job, project: project)
        end
      end

      include_examples 'returns a 404'
    end
  end
end
