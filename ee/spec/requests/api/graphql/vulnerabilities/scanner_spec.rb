# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.scanner', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  let_it_be(:fields) do
    <<~QUERY
      scanner {
        name
        externalId
      }
    QUERY
  end

  let_it_be(:query) do
    graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields))
  end

  let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: :container_scanning) }

  let_it_be(:vulnerabilities_scanner) do
    create(
      :vulnerabilities_scanner,
      name: 'Vulnerability Scanner',
      external_id: 'vulnerabilities_scanner',
      project: project
    )
  end

  let_it_be(:finding) do
    create(
      :vulnerabilities_finding,
      vulnerability: vulnerability,
      scanner: vulnerabilities_scanner
    )
  end

  subject { graphql_data.dig('vulnerabilities', 'nodes') }

  before do
    project.add_developer(user)
    stub_licensed_features(security_dashboard: true)

    post_graphql(query, current_user: user)
  end

  it 'returns a vulnerability scanner' do
    scanner = subject.first['scanner']

    expect(scanner['name']).to eq(vulnerabilities_scanner.name)
    expect(scanner['externalId']).to eq(vulnerabilities_scanner.external_id)
  end
end
