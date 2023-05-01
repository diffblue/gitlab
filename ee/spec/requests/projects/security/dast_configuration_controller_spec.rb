# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DastConfigurationController,
  feature_category: :dynamic_application_security_testing,
  type: :request do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe 'GET #show' do
    before do
      stub_licensed_features(security_dashboard: true)
      login_as(user)
    end

    include_context '"Security and Compliance" permissions' do
      let(:valid_request) { get project_security_configuration_dast_path(project) }

      before_request do
        project.add_developer(user)
      end
    end

    context 'feature available' do
      context 'user authorized' do
        before do
          project.add_developer(user)
        end

        it 'can access page' do
          get project_security_configuration_dast_path(project)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'user not authorized' do
        before do
          project.add_guest(user)
        end

        it 'sees a 404 error' do
          get project_security_configuration_dast_path(project)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'feature not available' do
      context "license doesn't support the feature" do
        before do
          stub_licensed_features(security_dashboard: false)
          project.add_developer(user)
        end

        it 'sees a 404 error' do
          get project_security_configuration_dast_path(project)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
