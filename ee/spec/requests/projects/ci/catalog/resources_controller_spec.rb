# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ci::Catalog::ResourcesController, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples 'basic get requests' do |action|
    let(:path) do
      if action == :index
        project_ci_catalog_resources_path(project)
      else
        project_ci_catalog_resource_path(project, id: 1)
      end
    end

    context 'with disabled FF `ci_namespace_catalog_experimental`' do
      before do
        stub_licensed_features(ci_namespace_catalog: true)
        stub_feature_flags(ci_namespace_catalog_experimental: false)
        project.add_developer(user)
      end

      it 'responds with 404' do
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with license for `ci_namespace_catalog`' do
      before do
        stub_licensed_features(ci_namespace_catalog: true)
      end

      context 'with enough privileges' do
        before do
          project.add_developer(user)
        end

        it 'responds with 200' do
          get path

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'without enough privileges' do
        before do
          project.add_reporter(user)
        end

        it 'responds with 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'without license for `ci_namespace_catalog`' do
      context 'with enough privileges' do
        before do
          project.add_developer(user)
        end

        it 'responds with 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'without enough privileges' do
        before do
          project.add_reporter(user)
        end

        it 'responds with 404' do
          get path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET #show' do
    it_behaves_like 'basic get requests', :show
  end

  describe 'GET #index' do
    it_behaves_like 'basic get requests', :index
  end
end
