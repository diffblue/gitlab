# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Integrations::Zentao::IssuesController, feature_category: :integrations do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:zentao_integration) { create(:zentao_integration, project: project) }

  before do
    stub_licensed_features(zentao_issues_integration: true)
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when zentao_issues_integration licensed feature is not available' do
      before do
        stub_licensed_features(zentao_issues_integration: false)
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

    context 'json request' do
      let(:zentao_issue) { [] }

      it 'returns a list of serialized zentao issues' do
        expect_next_instance_of(::Gitlab::Zentao::Query) do |query|
          expect(query).to receive(:issues).and_return(zentao_issue)
        end

        expect_next_instance_of(Integrations::ZentaoSerializers::IssueSerializer) do |serializer|
          expect(serializer).to receive(:represent).with(zentao_issue, project: project)
        end

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json
      end

      it 'renders bad request for Error' do
        expect_next_instance_of(::Gitlab::Zentao::Query) do |query|
          expect(query).to receive(:issues).and_raise(::Gitlab::Zentao::Client::Error)
        end
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['errors']).to match_array [s_('ZentaoIntegration|An error occurred while requesting data from the ZenTao service.')]
      end
    end
  end

  describe 'GET #show' do
    context 'when zentao_issues_integration licensed feature is not available' do
      before do
        stub_licensed_features(zentao_issues_integration: false)
      end

      it 'returns 404 status' do
        get :show, params: { namespace_id: project.namespace, project_id: project, id: 1 }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when zentao_issues_integration licensed feature is available' do
      let(:zentao_issue) { { 'from' => 'zentao' } }
      let(:issue_json) { { 'from' => 'backend' } }

      before do
        stub_licensed_features(zentao_issues_integration: true)

        expect_next_instance_of(::Gitlab::Zentao::Query) do |query|
          allow(query).to receive(:issue).and_return(zentao_issue)
        end

        allow_next_instance_of(Integrations::ZentaoSerializers::IssueDetailSerializer) do |serializer|
          allow(serializer).to receive(:represent).with(zentao_issue, project: project).and_return(issue_json)
        end
      end

      context 'with valid request' do
        it 'renders `show` template successfully' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'story-1' }

          expect(assigns(:issue_json)).to eq(issue_json)
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end

        it 'returns JSON response successfully' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'story-1', format: :json }

          expect(json_response).to eq(issue_json)
        end
      end

      context 'with bad request' do
        before do
          allow_next_instance_of(Integrations::ZentaoSerializers::IssueDetailSerializer) do |serializer|
            allow(serializer).to receive(:represent).and_raise(::Gitlab::Zentao::Client::Error)
          end
        end
        it 'renders `show` template successfully' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'story-1' }

          expect(assigns(:issue_json)).to be_nil
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end

        it 'returns JSON response with error messages' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'story-1', format: :json }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['errors']).to be_present
        end
      end

      context 'when the JSON fetched from ZenTao contains HTML' do
        let(:payload) { "<script>alert('XSS')</script>" }
        let(:issue_json) { { id: payload, title: payload, status: payload, labels: [payload] } }

        render_views

        it 'escapes the HTML in issue' do
          get :show, params: { namespace_id: project.namespace, project_id: project, id: 'story-1' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).not_to include(payload)
          expect(response.body).to include(html_escape(payload))
        end
      end
    end
  end
end
