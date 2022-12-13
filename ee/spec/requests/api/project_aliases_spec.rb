# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectAliases, api: true, feature_category: :source_code_management do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  context 'without premium license' do
    describe 'GET /project_aliases' do
      before do
        get api('/project_aliases', admin)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'GET /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      before do
        get api("/project_aliases/#{project_alias.name}", admin)
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'POST /project_aliases' do
      let(:project) { create(:project) }

      before do
        post api("/project_aliases", admin), params: { project_id: project.id, name: 'some-project' }
      end

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'DELETE /project_aliases/:name' do
      let(:project_alias) { create(:project_alias) }

      before do
        delete api("/project_aliases/#{project_alias.name}", admin)
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
        get api('/project_aliases', user)
      end

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

      before do
        get api("/project_aliases/#{alias_name}", user)
      end

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

      before do
        post api("/project_aliases", user), params: { project_id: project.id, name: alias_name }
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

      before do
        delete api("/project_aliases/#{alias_name}", user)
      end

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
