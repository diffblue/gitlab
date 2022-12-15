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
          let_it_be(:subgroup) { create(:group, parent: group) }
          let_it_be(:projects) { create_list(:project, 4, :public, group: group) }
          let_it_be(:subgroup_projects) { create_list(:project, 2, :public, group: subgroup) }

          before do
            stub_feature_flags(group_analytics_dashboards_page: group)
          end

          it 'succeeds' do
            request

            expect(response).to be_successful
          end

          it 'can accept a `query` params' do
            project = projects.first

            get build_dashboard_path(group_analytics_dashboards_path(group), [another_group, subgroup, project])

            expect(response).to be_successful

            expect(response.body.include?("data-namespaces")).to be_truthy
            expect(response.body).not_to include(parsed_response(another_group, false))
            expect(response.body).to include(parsed_response(subgroup, false))
            expect(response.body).to include(parsed_response(project))
          end

          it 'will only return the first 4 namespaces' do
            get build_dashboard_path(group_analytics_dashboards_path(group), [].concat(projects, [subgroup]))

            expect(response).to be_successful
            expect(response.body).not_to include(parsed_response(subgroup, false))

            projects.each do |project|
              expect(response.body).to include(parsed_response(project))
            end
          end

          it 'will return projects in a subgroup' do
            first_parent_project = projects.first
            params = [].concat(subgroup_projects, [subgroup], [first_parent_project])

            get build_dashboard_path(group_analytics_dashboards_path(group), params)

            expect(response).to be_successful
            expect(response.body).to include(parsed_response(subgroup, false))
            expect(response.body).to include(parsed_response(first_parent_project))

            subgroup_projects.each do |project|
              expect(response.body).to include(parsed_response(project))
            end
          end

          context 'when the feature is not enabled for that group' do
            let(:request) { get(group_analytics_dashboards_path(another_group)) }

            it_behaves_like 'forbidden response'
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
end
