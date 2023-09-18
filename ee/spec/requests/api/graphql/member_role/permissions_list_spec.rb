# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.member_role_permissions', feature_category: :system_access do
  include GraphqlHelpers

  let(:fields) do
    <<~QUERY
      nodes {
        availableFor
        description
        name
        requirement
        value
      }
    QUERY
  end

  let(:query) do
    graphql_query_for('memberRolePermissions', fields)
  end

  before do
    stub_const('MemberRole::ALL_CUSTOMIZABLE_PERMISSIONS',
      {
        admin_ability_one: {
          description: 'Allows admin access to do something.',
          minimal_level: Gitlab::Access::GUEST
        },
        admin_ability_two: {
          description: 'Allows admin access to do something else.',
          minimal_level: Gitlab::Access::DEVELOPER,
          requirement: :read_ability_two
        },
        read_ability_two: {
          description: 'Allows read access to do something else.',
          minimal_level: Gitlab::Access::GUEST
        }
      }
    )
    stub_const('::MemberRole::ALL_CUSTOMIZABLE_PROJECT_PERMISSIONS',
      [:admin_ability_one, :read_ability_two]
    )
    stub_const('::MemberRole::ALL_CUSTOMIZABLE_GROUP_PERMISSIONS',
      [:admin_ability_two, :read_ability_two]
    )

    post_graphql(query)
  end

  subject { graphql_data.dig('memberRolePermissions', 'nodes') }

  it_behaves_like 'a working graphql query'

  it 'returns all customizable ablities' do
    expected_result = [
      { 'availableFor' => ['project'], 'description' => 'Allows admin access to do something.',
        'name' => 'Admin ability one', 'requirement' => nil, 'value' => 'admin_ability_one' },
      { 'availableFor' => %w[project group], 'description' => 'Allows read access to do something else.',
        'name' => 'Read ability two', 'requirement' => nil, 'value' => 'read_ability_two' },
      { 'availableFor' => ['group'], 'description' => "Allows admin access to do something else.",
        'requirement' => 'read_ability_two', 'name' => 'Admin ability two', 'value' => 'admin_ability_two' }
    ]

    expect(subject).to match_array(expected_result)
  end
end
