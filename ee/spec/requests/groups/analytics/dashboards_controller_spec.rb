# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::DashboardsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:another_group) { create(:group) }
  let_it_be(:user) do
    create(:user).tap do |user|
      group.add_reporter(user)
      another_group.add_reporter(user)
    end
  end

  let(:request) { get(group_analytics_dashboards_path(group)) }

  shared_examples 'forbidden response' do
    it 'returns forbidden response' do
      request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET index' do
    context 'when user is not logged in' do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true)
        stub_feature_flags(group_analytics_dashboards_page: true)
      end

      it 'redirects the user to the login page' do
        request

        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'when user is not authorized' do
      let_it_be(:user) { create(:user) }

      before do
        stub_licensed_features(group_level_analytics_dashboard: true)
        stub_feature_flags(group_analytics_dashboards_page: true)

        sign_in(user)
      end

      it_behaves_like 'forbidden response'
    end

    context 'when user is logged in' do
      before do
        sign_in(user)
      end

      context 'when the license is not available' do
        before do
          stub_licensed_features(group_level_analytics_dashboard: false)
        end

        context 'when the feature is disabled' do
          before do
            stub_feature_flags(group_analytics_dashboards_page: false)
          end

          it_behaves_like 'forbidden response'
        end

        context 'when the feature is enabled' do
          before do
            stub_feature_flags(group_analytics_dashboards_page: true)
          end

          it_behaves_like 'forbidden response'
        end
      end

      context 'when the license is available' do
        before do
          stub_licensed_features(group_level_analytics_dashboard: true)
        end

        context 'when the feature is disabled' do
          before do
            stub_feature_flags(group_analytics_dashboards_page: false)
          end

          it_behaves_like 'forbidden response'
        end

        context 'when the feature is enabled' do
          before do
            stub_feature_flags(group_analytics_dashboards_page: group)
          end

          it 'succeeds' do
            request

            expect(response).to be_successful
          end

          context 'when the feature is not enabled for that group' do
            let(:request) { get(group_analytics_dashboards_path(another_group)) }

            it_behaves_like 'forbidden response'
          end
        end
      end
    end
  end
end
