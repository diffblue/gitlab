# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Integrations::Jira::IssuesController do
  include ProjectForksHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:jira) { create(:jira_integration, project: project, issues_enabled: true, project_key: 'TEST') }

  before do
    stub_licensed_features(jira_issues_integration: true)
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when jira_issues_integration licensed feature is not available' do
      before do
        stub_licensed_features(jira_issues_integration: false)
      end

      it 'returns 404 status' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'unauthorized when external service denies access' do
      subject { get :index, params: { namespace_id: project.namespace, project_id: project } }
    end

    it 'renders the "index" template' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'tracks usage' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter)
        .to receive(:track_event)
        .with('i_ecosystem_jira_service_list_issues', values: user.id)

      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    context 'when project has moved' do
      let(:new_project) { create(:project) }

      before do
        project.route.destroy!
        new_project.redirect_routes.create!(path: project.full_path)
        new_project.add_developer(user)
      end

      it 'redirects to the new issue tracker from the old one' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to redirect_to(Gitlab::Routing.url_helpers.project_integrations_jira_issues_path(new_project))
        expect(response).to have_gitlab_http_status(:moved_permanently)
      end
    end

    context 'json request' do
      let(:jira_issues) { [] }

      it 'returns a list of serialized jira issues' do
        expect_next_instance_of(Projects::Integrations::Jira::IssuesFinder) do |finder|
          expect(finder).to receive(:execute).and_return(jira_issues)
        end

        expect_next_instance_of(Integrations::JiraSerializers::IssueSerializer) do |serializer|
          expect(serializer).to receive(:represent).with(jira_issues, project: project)
        end

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json
      end

      it 'renders bad request for IntegrationError' do
        expect_any_instance_of(Projects::Integrations::Jira::IssuesFinder).to receive(:execute)
          .and_raise(Projects::Integrations::Jira::IssuesFinder::IntegrationError, 'Integration error')
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['errors']).to eq ['Integration error']
      end

      it 'renders bad request for RequestError' do
        expect_any_instance_of(Projects::Integrations::Jira::IssuesFinder).to receive(:execute)
          .and_raise(Projects::Integrations::Jira::IssuesFinder::RequestError, 'Request error')
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['errors']).to eq ['Request error']
      end

      it 'sets pagination headers' do
        expect_next_instance_of(Projects::Integrations::Jira::IssuesFinder) do |finder|
          expect(finder).to receive(:execute).and_return(jira_issues)
        end

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

        expect(response).to include_pagination_headers
        expect(response.headers['X-Page']).to eq '1'
        expect(response.headers['X-Per-Page']).to eq Jira::Requests::Issues::ListService::PER_PAGE.to_s
        expect(response.headers['X-Total']).to eq '0'
      end

      context 'when parameters are passed' do
        shared_examples 'proper parameter values' do
          it 'properly set the values' do
            expect_next_instance_of(Projects::Integrations::Jira::IssuesFinder, project, expected_params) do |finder|
              expect(finder).to receive(:execute).and_return(jira_issues)
            end

            get :index, params: { namespace_id: project.namespace, project_id: project }.merge(params), format: :json
          end
        end

        context 'when there are no params' do
          it_behaves_like 'proper parameter values' do
            let(:params) { {} }
            let(:expected_params) { { 'state' => 'opened', 'sort' => 'created_date' } }
          end
        end

        context 'when pagination params' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'page' => '12', 'per_page' => '20' } }
            let(:expected_params) { { 'page' => '12', 'per_page' => '20', 'state' => 'opened', 'sort' => 'created_date' } }
          end
        end

        context 'when state is closed' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'state' => 'closed' } }
            let(:expected_params) { { 'state' => 'closed', 'sort' => 'updated_desc' } }
          end
        end

        context 'when status param' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'status' => 'jira status' } }
            let(:expected_params) { { 'state' => 'opened', 'status' => 'jira status', 'sort' => 'created_date' } }
          end
        end

        context 'when labels param' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'labels' => %w[label1 label2] } }
            let(:expected_params) { { 'state' => 'opened', 'labels' => %w[label1 label2], 'sort' => 'created_date' } }
          end
        end

        context 'when author_username param' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'author_username' => 'some reporter' } }
            let(:expected_params) { { 'state' => 'opened', 'author_username' => 'some reporter', 'sort' => 'created_date' } }
          end
        end

        context 'when assignee_username param' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'assignee_username' => 'some assignee' } }
            let(:expected_params) { { 'state' => 'opened', 'assignee_username' => 'some assignee', 'sort' => 'created_date' } }
          end
        end

        context 'when invalid params' do
          it_behaves_like 'proper parameter values' do
            let(:params) { { 'invalid' => '12' } }
            let(:expected_params) { { 'state' => 'opened', 'sort' => 'created_date' } }
          end
        end
      end
    end
  end

  describe 'GET #show' do
    context 'when jira_issues_integration licensed feature is not available' do
      before do
        stub_licensed_features(jira_issues_integration: false)
      end

      it 'returns 404 status' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: 1 }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when jira_issues_integration licensed feature is available' do
      let(:jira_issue) { { 'from' => 'jira' } }
      let(:issue_json) { { 'from' => 'backend' } }

      before do
        stub_licensed_features(jira_issues_integration: true)

        allow_next_found_instance_of(Integrations::Jira) do |service|
          allow(service).to receive(:find_issue).with('1', rendered_fields: true).and_return(jira_issue)
        end

        allow_next_instance_of(Integrations::JiraSerializers::IssueDetailSerializer) do |serializer|
          allow(serializer).to receive(:represent).with(jira_issue, project: project).and_return(issue_json)
        end
      end

      it 'renders `show` template' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: 1 }

        expect(assigns(:issue_json)).to eq(issue_json)
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it 'returns JSON response' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: 1, format: :json }

        expect(json_response).to eq(issue_json)
      end

      context 'when the JSON fetched from Jira contains HTML' do
        let(:payload) { "<script>alert('XSS')</script>" }
        let(:issue_json) { { title: payload, references: { relative: payload } } }

        render_views

        it 'escapes the HTML in issue titles and references' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 1 }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).not_to include(payload)
          expect(response.body).to include(html_escape(payload))
        end
      end
    end
  end
end
