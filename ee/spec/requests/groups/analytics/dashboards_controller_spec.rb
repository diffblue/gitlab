# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::DashboardsController, feature_category: :subgroups do
  let_it_be(:group) { create(:group) }
  let_it_be(:another_group) { create(:group) }
  let_it_be(:user) do
    create(:user).tap do |user|
      group.add_reporter(user)
      another_group.add_reporter(user)
    end
  end

  shared_examples 'forbidden response' do
    it 'returns forbidden response' do
      request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET index' do
    let(:request) { get(group_analytics_dashboards_path(group)) }

    before do
      stub_licensed_features(group_level_analytics_dashboard: true)
    end

    context 'when user is not logged in' do
      it 'redirects the user to the login page' do
        request

        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'when user is logged in' do
      before do
        sign_in(user)
      end

      it 'redirects to value stream dashboards' do
        request

        expect(response)
          .to redirect_to(value_streams_dashboard_group_analytics_dashboards_path(group))
      end
    end
  end

  describe 'GET value_streams_dashboard' do
    let(:request) { get(value_streams_dashboard_group_analytics_dashboards_path(group)) }

    context 'when user is not logged in' do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true)
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

        it_behaves_like 'forbidden response'
      end

      context 'when the license is available' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:projects) { create_list(:project, 4, :public, group: group) }
        let_it_be(:subgroup_projects) { create_list(:project, 2, :public, group: subgroup) }

        before do
          stub_licensed_features(group_level_analytics_dashboard: true)
        end

        it 'succeeds' do
          request

          expect(response).to be_successful
        end

        it 'can accept a `query` params' do
          project = projects.first

          get build_dashboard_path(
            value_streams_dashboard_group_analytics_dashboards_path(group),
            [another_group, subgroup, project]
          )

          expect(response).to be_successful

          expect(response.body.include?("data-namespaces")).to be_truthy
          expect(response.body).not_to include(parsed_response(another_group, false))
          expect(response.body).to include(parsed_response(subgroup, false))
          expect(response.body).to include(parsed_response(project))
        end

        it 'will only return the first 4 namespaces' do
          get build_dashboard_path(
            value_streams_dashboard_group_analytics_dashboards_path(group),
            [].concat(projects, [subgroup])
          )

          expect(response).to be_successful
          expect(response.body).not_to include(parsed_response(subgroup, false))

          projects.each do |project|
            expect(response.body).to include(parsed_response(project))
          end
        end

        it 'will return projects in a subgroup' do
          first_parent_project = projects.first
          params = [].concat(subgroup_projects, [subgroup], [first_parent_project])

          get build_dashboard_path(value_streams_dashboard_group_analytics_dashboards_path(group), params)

          expect(response).to be_successful
          expect(response.body).to include(parsed_response(subgroup, false))
          expect(response.body).to include(parsed_response(first_parent_project))

          subgroup_projects.each do |project|
            expect(response.body).to include(parsed_response(project))
          end
        end

        it 'tracks page view on usage ping' do
          expect(::Gitlab::UsageDataCounters::ValueStreamsDashboardCounter).to receive(:count).with(:views)

          request

          expect(response).to be_successful
        end

        def parsed_response(namespace, is_project = true)
          json = { name: namespace.name, full_path: namespace.full_path, is_project: is_project }.to_json
          HTMLEntities.new.encode(json)
        end

        def build_dashboard_path(path, namespaces)
          "#{path}?query=#{namespaces.map(&:full_path).join(',')}"
        end
      end
    end
  end
end

RSpec.describe Groups::Analytics::DashboardsController, type: :controller, feature_category: :product_analytics do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) do
    create(:user).tap do |user|
      group.add_reporter(user)
    end
  end

  before do
    stub_licensed_features(group_level_analytics_dashboard: true)
    sign_in(user)
  end

  it_behaves_like 'tracking unique visits', :value_streams_dashboard do
    let(:request_params) { { group_id: group.to_param } }
    let(:target_id) { 'g_metrics_comparison_page' }
  end
end
