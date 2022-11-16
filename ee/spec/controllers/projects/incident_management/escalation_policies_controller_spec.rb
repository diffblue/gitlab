# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentManagement::EscalationPoliciesController, feature_category: :incident_management do
  let_it_be(:user_with_read_permissions) { create(:user) }
  let_it_be(:user_with_admin_permissions) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:current_user) { user_with_admin_permissions }

  describe 'GET #index' do
    let(:request) do
      get :index, params: { project_id: project.to_param, namespace_id: project.namespace.to_param }
    end

    before do
      project.add_reporter(user_with_read_permissions)
      project.add_maintainer(user_with_admin_permissions)

      stub_licensed_features(oncall_schedules: true, escalation_policies: true)

      sign_in(current_user)
    end

    context 'with read permissions' do
      let(:current_user) { user_with_read_permissions }

      it 'renders index with 200 status code' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'with admin permissions' do
      let(:current_user) { user_with_admin_permissions }

      it 'renders index with 200 status code' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context 'unauthorized' do
      let(:current_user) { create(:user) }

      it 'responds with 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unavailable feature' do
      before do
        stub_licensed_features(escalation_policies: false)
      end

      it 'responds with 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unavailable on-call schedules feature' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it 'responds with 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
