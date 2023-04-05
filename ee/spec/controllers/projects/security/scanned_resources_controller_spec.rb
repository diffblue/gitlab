# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ScannedResourcesController,
  feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
  let(:action_params) { { project_id: project, namespace_id: project.namespace, pipeline_id: pipeline } }

  before do
    stub_licensed_features(dast: true, security_dashboard: true)

    sign_in(user)
  end

  describe 'GET index' do
    let(:parsed_csv_data) { CSV.parse(subject.body, headers: true) }

    subject(:request) { get :index, params: action_params, format: :csv }

    before do
      project.add_developer(user)
    end

    include_context '"Security and Compliance" permissions' do
      let(:valid_request) { request }
    end

    context 'when DAST security scan is found' do
      before do
        create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
          create(:ee_ci_job_artifact, :dast, job: job, project: project)
        end
      end

      it 'returns the CSV data' do
        expect(subject).to have_gitlab_http_status(:ok)
        expect(parsed_csv_data.size).to be_positive
      end

      context 'when pipeline_id is from a dangling pipeline' do
        let(:pipeline) do
          create(:ci_pipeline,
            source: :ondemand_dast_scan,
            project: project,
            ref: 'master',
            sha: project.commit.id)
        end

        it 'returns the CSV data' do
          expect(subject).to have_gitlab_http_status(:ok)
          expect(parsed_csv_data.size).to be_positive
        end
      end

      context 'when the pipeline id is missing' do
        let(:action_params) { { project_id: project, namespace_id: project.namespace } }

        it 'raises an error when pipeline_id param is missing' do
          expect { subject }.to raise_error(ActionController::ParameterMissing)
        end
      end
    end
  end
end
