# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.identifiers', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  let_it_be(:fields) do
    <<~QUERY
      identifiers {
        name
        externalType
        externalId
        url
      }
    QUERY
  end

  let_it_be(:query) do
    graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields))
  end

  let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: :container_scanning) }

  let_it_be(:finding_identifier) do
    create(
      :vulnerabilities_identifier,
      external_type: 'CVE',
      external_id: 'CVE-2020-1211',
      name: 'CVE-2020-1211',
      url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2020-1211'
    )
  end

  let_it_be(:finding) do
    create(
      :vulnerabilities_finding,
      vulnerability: vulnerability
    )
  end

  let_it_be(:vulnerabilities_finding_identifier) do
    create(:vulnerabilities_finding_identifier, identifier: finding_identifier, finding: finding)
  end

  subject { graphql_data.dig('vulnerabilities', 'nodes') }

  before do
    project.add_developer(user)
    stub_licensed_features(security_dashboard: true)

    post_graphql(query, current_user: user)
  end

  it 'returns a vulnerability identifiers' do
    identifier = subject.first['identifiers'].first

    expect(identifier['name']).to eq(finding_identifier.name)
    expect(identifier['externalType']).to eq(finding_identifier.external_type)
    expect(identifier['externalId']).to eq(finding_identifier.external_id)
    expect(identifier['url']).to eq(finding_identifier.url)
  end
end
