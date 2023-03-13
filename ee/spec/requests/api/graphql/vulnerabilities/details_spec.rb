# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.details', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }
  let_it_be(:all_field_types_for_query) do
    <<~FIELD_TYPES
      ... on VulnerabilityDetailBoolean {
        description
        fieldName
        name
        value
      }
      ... on VulnerabilityDetailCode {
        fieldName
        lang
        name
        value
      }
      ... on VulnerabilityDetailCommit {
        description
        fieldName
        name
        value
      }
      ... on VulnerabilityDetailDiff {
        after
        before
        description
        fieldName
        name
      }
      ... on VulnerabilityDetailFileLocation {
        description
        fieldName
        fileName
        lineEnd
        lineStart
        name
      }
      ... on VulnerabilityDetailInt {
        description
        fieldName
        name
        value
      }
      ... on VulnerabilityDetailMarkdown {
        description
        fieldName
        name
        value
      }
      ... on VulnerabilityDetailModuleLocation {
        description
        fieldName
        moduleName
        name
        offset
      }
      ... on VulnerabilityDetailText {
        description
        fieldName
        name
        value
      }
      ... on VulnerabilityDetailUrl {
        description
        fieldName
        href
        name
        text
      }
    FIELD_TYPES
  end

  let_it_be(:fields) do
    <<~QUERY
      details {
        __typename
        #{all_field_types_for_query}
        ... on VulnerabilityDetailTable {
          description
          fieldName
          name
          headers {
            __typename
            #{all_field_types_for_query}
          }
          rows {
            row {
              __typename
              #{all_field_types_for_query}
            }
          }
        }
        ... on VulnerabilityDetailList {
          description
          fieldName
          items {
            __typename
            #{all_field_types_for_query}
          }
          name
        }
      }
    QUERY
  end

  let_it_be(:query) do
    graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields))
  end

  let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: :container_scanning) }

  let_it_be(:finding) do
    create(
      :vulnerabilities_finding,
      :with_details,
      vulnerability: vulnerability
    )
  end

  subject { graphql_data.dig('vulnerabilities', 'nodes') }

  before do
    project.add_developer(user)
    stub_licensed_features(security_dashboard: true)

    post_graphql(query, current_user: user)
  end

  let(:expected_details) do
    Gitlab::Json.parse(
      File.read(Rails.root.join('ee/spec/fixtures/api/graphql/vulnerabilities/details_expectation.json'))
    )
  end

  it 'returns a vulnerability details' do
    expect(subject.first['details']).to eq(expected_details)
  end
end
