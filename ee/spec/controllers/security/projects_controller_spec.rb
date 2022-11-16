# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ProjectsController, feature_category: :vulnerability_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'GET #index' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        get :index
      end
    end

    context 'with an authenticated user' do
      before do
        stub_licensed_features(security_dashboard: true)

        user.security_dashboard_projects << project

        sign_in(user)
      end

      it "returns the current user's security dashboard projects" do
        get :index

        aggregate_failures 'expect successful response containing the project with a remove path' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['projects'].count).to be(1)

          dashboard_project = json_response['projects'].first
          expect(dashboard_project['id']).to be(project.id)
          expect(dashboard_project['remove_path']).to eq(security_project_path(id: project.id))
        end
      end

      it 'sets a polling interval header' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Poll-Interval']).to eq('120000')
      end
    end
  end

  describe 'POST #create' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        post :create
      end
    end

    context 'with an authenticated user' do
      let(:params) { { project_ids: [project.id] } }

      subject { post :create, params: params }

      before do
        stub_licensed_features(security_dashboard: true)

        project.add_developer(user)
        sign_in(user)
      end

      it "adds the given projects to the current user's security dashboard" do
        subject

        aggregate_failures 'expect successful response and project added to dashboard' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(user.reload.security_dashboard_projects).to contain_exactly(project)
          expect(json_response).to eq({
            'added' => [project.id],
            'duplicate' => [],
            'invalid' => []
          })
        end
      end

      context 'when given a project that is already added to the dashboard' do
        it 'does not add the same project twice and returns the duplicate IDs in the response' do
          user.security_dashboard_projects << project

          subject

          aggregate_failures 'expect successful response and no duplicate project added to dashboard' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(user.reload.security_dashboard_projects.count).to be(1)
            expect(json_response).to eq({
              'added' => [],
              'duplicate' => [project.id],
              'invalid' => []
            })
          end
        end
      end

      context 'when given an invalid project ID' do
        let(:params) { { project_ids: [-1] } }

        it 'does not error and includes them in the response' do
          subject

          aggregate_failures 'expect successful response and no project added to dashboard' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(user.reload.security_dashboard_projects).to be_empty
            expect(json_response).to eq({
              'added' => [],
              'duplicate' => [],
              'invalid' => [-1]
            })
          end
        end
      end
    end

    context 'with an authenticated auditor' do
      it 'allows them to add projects to the dashboard' do
        stub_licensed_features(security_dashboard: true)
        auditor = create(:auditor)

        sign_in(auditor)

        post :create, params: { project_ids: [project.id] }

        aggregate_failures 'expect successful response and project added to dashboard' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(auditor.reload.security_dashboard_projects).to contain_exactly(project)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with an authenticated user' do
      before do
        stub_licensed_features(security_dashboard: true)

        user.security_dashboard_projects << project

        sign_in(user)
      end

      subject { delete :destroy, params: { id: project.id } }

      context 'and the instance does not have an Ultimate license' do
        it '404s' do
          stub_licensed_features(security_dashboard: false)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it "removes the project from the current user's security dashboard" do
        subject

        aggregate_failures 'expect successful response and project removed from dashboard' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(user.reload.security_dashboard_projects).to be_empty
        end
      end

      context "when given a project not on the current user's security dashboard" do
        it 'does nothing and returns 204' do
          delete :destroy, params: { id: -1 }

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end

    context 'when the user is not authenticated' do
      it 'redirects the user to the sign in page' do
        delete :destroy, params: { id: project.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
