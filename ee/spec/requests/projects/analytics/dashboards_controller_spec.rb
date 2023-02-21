# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::DashboardsController, type: :request, feature_category: :product_analytics do
  describe 'GET /:namespace/:project/-/analytics/dashboards' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    before do
      login_as(user)
    end

    it 'returns 200 response' do
      get project_analytics_dashboards_path(project)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
