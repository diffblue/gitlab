# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devopsAdoptionEnabledNamespaces', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user, :admin) }
  let_it_be(:group) { create(:group, name: 'my-group') }

  let_it_be(:enabled_namespace) do
    create(:devops_adoption_enabled_namespace, namespace: group, display_namespace: group)
  end

  let_it_be(:expected_metrics) do
    result = {}
    Analytics::DevopsAdoption::Snapshot::BOOLEAN_METRICS.each.with_index do |m, i|
      result[m] = i.odd?
    end
    Analytics::DevopsAdoption::Snapshot::NUMERIC_METRICS.each do |m|
      result[m] = rand(10)
    end
    result[:total_projects_count] += 10
    result
  end

  let_it_be(:snapshot) do
    create(:devops_adoption_snapshot, namespace: group, **expected_metrics, end_time: DateTime.parse('2021-01-31').end_of_month)
  end

  let(:query) do
    metrics = Analytics::DevopsAdoption::Snapshot::ADOPTION_METRICS.map { |m| m.to_s.camelize(:lower) }

    graphql_query_for(:devopsAdoptionEnabledNamespaces, { display_namespace_id: group.to_gid.to_s }, %(
      nodes {
        id
        namespace {
          name
        }
        displayNamespace {
          name
        }
        snapshots {
          nodes {
            #{metrics.join(' ')}
          }
        }
        latestSnapshot {
          #{metrics.join(' ')}
        }
      }
    ))
  end

  before do
    stub_licensed_features(instance_level_devops_adoption: true, group_level_devops_adoption: true)

    travel_to(DateTime.parse('2021-02-02')) do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'returns measurement objects' do
    expected_snapshot = expected_metrics.transform_keys { |key| key.to_s.camelize(:lower) }

    expect(graphql_data['devopsAdoptionEnabledNamespaces']['nodes']).to eq(
      [
        {
          'id' => enabled_namespace.to_gid.to_s,
          'namespace' => { 'name' => group.name },
          'displayNamespace' => { 'name' => group.name },
          'snapshots' => { 'nodes' => [expected_snapshot] },
          'latestSnapshot' => expected_snapshot
        }
      ])
  end
end
