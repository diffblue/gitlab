# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::DashboardsController, type: :request, feature_category: :product_analytics do
  using RSpec::Parameterized::TableSyntax

  describe 'GET /:namespace/:project/-/analytics/dashboards' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }

    before do
      login_as(user)
    end

    shared_examples 'returns not found' do
      it 'returns 404 response' do
        send_dashboards_request

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not increment counter' do
        expect(Gitlab::UsageDataCounters::ProductAnalyticsCounter).not_to receive(:count)

        send_dashboards_request
      end
    end

    shared_examples 'returns success' do
      it 'returns 200 response' do
        send_dashboards_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'increments counter' do
        expect(Gitlab::UsageDataCounters::ProductAnalyticsCounter).to receive(:count).with(:view_dashboard)

        send_dashboards_request
      end
    end

    context 'with the feature flag disabled' do
      before do
        stub_feature_flags(combined_analytics_dashboards: false)
      end

      it_behaves_like 'returns not found'
    end

    context 'with the feature flag enabled' do
      before do
        stub_feature_flags(combined_analytics_dashboards: true)
      end

      context 'without the licensed feature' do
        before do
          stub_licensed_features(combined_project_analytics_dashboards: false)
        end

        it_behaves_like 'returns not found'
      end

      context 'with the licensed feature' do
        where(:access_level, :example_to_run) do
          nil         | 'returns not found'
          :reporter   | 'returns success'
          :developer  | 'returns success'
          :maintainer | 'returns success'
        end

        with_them do
          let(:user) { create(:user) }

          before do
            stub_licensed_features(combined_project_analytics_dashboards: true)
            project.add_member(user, access_level)
          end

          it_behaves_like params[:example_to_run]
        end

        it 'does not count views for the dashboard listing' do
          expect(Gitlab::UsageDataCounters::ProductAnalyticsCounter).not_to receive(:count)

          get project_analytics_dashboards_path(project)
        end
      end
    end

    private

    def send_dashboards_request
      get project_analytics_dashboards_path(project, vueroute: 'dashboard_audience')
    end
  end
end
