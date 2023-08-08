# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting Alert Management Integrations', feature_category: :incident_management do
  include ::Gitlab::Routing.url_helpers
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }
  let_it_be(:active_http_integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:inactive_http_integration) { create(:alert_management_http_integration, :inactive, project: project) }
  let_it_be(:project_alerting_setting) { create(:project_alerting_setting, project: project) }
  let_it_be(:other_project_http_integration) { create(:alert_management_http_integration) }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('AlertManagementIntegration')}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementIntegrations', {}, fields)
    )
  end

  before do
    stub_licensed_features(multiple_alert_http_integrations: true)
  end

  context 'with integrations' do
    let(:integrations) { graphql_data.dig('project', 'alertManagementIntegrations', 'nodes') }

    context 'without project permissions' do
      let(:user) { create(:user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query that returns no data'
    end

    context 'with project permissions' do
      before do
        project.add_maintainer(current_user)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query that returns data'

      specify { expect(integrations.size).to eq(3) }

      it 'returns the correct properties of the integrations' do
        expect(integrations).to include(
          {
            'id' => GitlabSchema.id_from_object(active_http_integration).to_s,
            'type' => 'HTTP',
            'name' => active_http_integration.name,
            'active' => active_http_integration.active,
            'token' => active_http_integration.token,
            'url' => active_http_integration.url,
            'apiUrl' => nil
          },
          {
            'id' => GitlabSchema.id_from_object(inactive_http_integration).to_s,
            'type' => 'HTTP',
            'name' => inactive_http_integration.name,
            'active' => inactive_http_integration.active,
            'token' => inactive_http_integration.token,
            'url' => inactive_http_integration.url,
            'apiUrl' => nil
          },
          {
            'id' => GitlabSchema.id_from_object(prometheus_integration).to_s,
            'type' => 'PROMETHEUS',
            'name' => 'Prometheus',
            'active' => prometheus_integration.manual_configuration?,
            'token' => project_alerting_setting.token,
            'url' => "http://localhost/#{project.full_path}/prometheus/alerts/notify.json",
            'apiUrl' => prometheus_integration.api_url
          }
        )
      end
    end
  end
end
