# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectAliases, :aggregate_failures, api: true, feature_category: :source_code_management do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:path) { '/project_aliases' }

  context 'without premium license' do
    describe 'GET /project_aliases' do
      it_behaves_like 'GET request permissions for admin mode' do
        let(:success_status_code) { :forbidden }
      end

      before do
        get api(path, admin, admin_mode: true)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'GET /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      it_behaves_like 'GET request permissions for admin mode' do
        let(:path) { "/project_aliases/#{project_alias.name}" }
        let(:success_status_code) { :forbidden }
      end

      before do
        get api("/project_aliases/#{project_alias.name}", admin, admin_mode: true)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'POST /project_aliases' do
      let(:project) { create(:project) }

      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { { project_id: project.id, name: 'some-project' } }
        let(:success_status_code) { :forbidden }
      end

      before do
        post api(path, admin, admin_mode: true), params: { project_id: project.id, name: 'some-project' }
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'DELETE /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }
      let(:path) { "/project_aliases/#{project_alias.name}" }

      it_behaves_like 'DELETE request permissions for admin mode' do
        let(:success_status_code) { :forbidden }
      end

      before do
        delete api(path, admin, admin_mode: true)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  context 'with premium license' do
    shared_examples_for 'GitLab administrator only API endpoint' do
      context 'anonymous user' do
        let(:user) { nil }

        it 'returns 401' do
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'regular user' do
        it 'returns 403' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    before do
      stub_licensed_features(project_aliases: true)
    end

    describe 'GET /project_aliases' do
      before do
        get api(path, user, admin_mode: true)
      end

      it_behaves_like 'GET request permissions for admin mode'

      it_behaves_like 'GitLab administrator only API endpoint'

      context 'admin' do
        let(:user) { admin }
        let!(:project_alias_1) { create(:project_alias) }
        let!(:project_alias_2) { create(:project_alias) }

        it 'returns the project aliases list' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/project_aliases', dir: 'ee')
          expect(response).to include_pagination_headers
        end
      end
    end

    describe 'GET /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }
      let(:alias_name) { project_alias.name }
      let(:path) { "/project_aliases/#{alias_name}" }

      before do
        get api(path, user, admin_mode: true)
      end

      it_behaves_like 'GET request permissions for admin mode'

      it_behaves_like 'GitLab administrator only API endpoint'

      context 'admin' do
        let(:user) { admin }

        context 'existing project alias' do
          it 'returns the project alias' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/project_alias', dir: 'ee')
          end
        end

        context 'non-existent project alias' do
          let(:alias_name) { 'some-project' }

          it 'returns 404' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    describe 'POST /project_aliases' do
      let(:project) { create(:project) }
      let(:project_alias) { create(:project_alias) }
      let(:alias_name) { project_alias.name }
      let(:params) { { project_id: project.id, name: alias_name } }

      before do
        post api(path, user, admin_mode: true), params: params
      end

      it_behaves_like 'POST request permissions for admin mode' do
        let(:alias_name) { 'some-project' }
      end

      it_behaves_like 'GitLab administrator only API endpoint'

      context 'admin' do
        let(:user) { admin }

        context 'existing project alias' do
          it 'returns 400' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'non-existent project alias' do
          let(:alias_name) { 'some-project' }

          it 'returns 200' do
            expect(response).to have_gitlab_http_status(:created)
            expect(response).to match_response_schema('public_api/v4/project_alias', dir: 'ee')
          end
        end
      end
    end

    describe 'DELETE /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }
      let(:alias_name) { project_alias.name }
      let(:path) { "/project_aliases/#{alias_name}" }

      before do
        delete api(path, user, admin_mode: true)
      end

      it_behaves_like 'DELETE request permissions for admin mode'

      it_behaves_like 'GitLab administrator only API endpoint'

      context 'admin' do
        let(:user) { admin }

        context 'existing project alias' do
          it 'returns 204' do
            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        context 'non-existent project alias' do
          let(:alias_name) { 'some-project' }

          it 'returns 404' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
