# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DevOps Adoption (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:current_user) { create(:user, :admin) }
    let_it_be(:group) { create(:group, name: 'my-group') }
    let_it_be(:sub_group) { create(:group, parent: group, name: 'my-sub-group') }

    let_it_be(:enabled_namespace) do
      create(:devops_adoption_enabled_namespace, namespace: group, display_namespace: group)
    end

    let_it_be(:second_enabled_namespace) do
      create(:devops_adoption_enabled_namespace, namespace: sub_group, display_namespace: group)
    end

    let_it_be(:expected_metrics) do
      result = {}
      Analytics::DevopsAdoption::Snapshot::BOOLEAN_METRICS.each.with_index do |m, i|
        result[m] = i.odd?
      end
      Analytics::DevopsAdoption::Snapshot::NUMERIC_METRICS.each.with_index do |m, i|
        result[m] = i
      end
      result[:total_projects_count] += 10
      result
    end

    let_it_be(:snapshot) do
      create(:devops_adoption_snapshot, namespace: group, **expected_metrics, end_time: DateTime.parse('2021-01-31').end_of_month)
    end

    before do
      stub_licensed_features(instance_level_devops_adoption: true, group_level_devops_adoption: true)
      travel_back
    end

    path = 'analytics/devops_reports/devops_adoption/graphql/queries/devops_adoption_enabled_namespaces.query.graphql'

    it "graphql/#{path}.json" do
      query = get_graphql_query_as_string(path, ee: true)

      travel_to(DateTime.parse('2021-02-02')) do
        post_graphql(query, current_user: current_user, variables: { displayNamespaceId: group.to_gid.to_s })
      end

      expect_graphql_errors_to_be_empty
    end

    query_path = 'analytics/devops_reports/devops_adoption/graphql/queries/devops_adoption_overview_chart.query.graphql'

    it "graphql/#{query_path}.json" do
      query = get_graphql_query_as_string(query_path, ee: true)

      travel_to(DateTime.parse('2021-02-02')) do
        post_graphql(query, current_user: current_user, variables: { displayNamespaceId: group.to_gid.to_s, startDate: '2020-06-31', endDate: '2021-03-31' } )
      end

      expect_graphql_errors_to_be_empty
    end
  end
end
