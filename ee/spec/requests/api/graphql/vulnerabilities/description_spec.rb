# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.description', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  let_it_be(:fields) do
    <<~QUERY
      description
      descriptionHtml
    QUERY
  end

  let_it_be(:query) do
    graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields))
  end

  let(:vulnerability_description) { nil }
  let(:finding_description) { nil }

  let!(:vulnerability) { create(:vulnerability, description: vulnerability_description, project: project, report_type: :container_scanning) }

  let!(:finding) do
    create(
      :vulnerabilities_finding,
      description: finding_description,
      vulnerability: vulnerability
    )
  end

  subject { graphql_data.dig('vulnerabilities', 'nodes') }

  before do
    project.add_developer(user)
    stub_licensed_features(security_dashboard: true)

    post_graphql(query, current_user: user)
  end

  context 'when vulnerability has no description and finding has description' do
    let(:vulnerability_description) { nil }
    let(:finding_description) { '# Finding' }

    it 'returns finding information' do
      rendered_markdown = '<h1 data-sourcepos="1:1-1:9" dir="auto">&#x000A;<a id="user-content-finding" class="anchor" href="#finding" aria-hidden="true"></a>Finding</h1>'

      expect(subject.first['description']).to eq('# Finding')
      expect(subject.first['descriptionHtml']).to eq(rendered_markdown)
    end
  end

  context 'when vulnerability has description and finding has description' do
    let(:vulnerability_description) { '# Vulnerability' }
    let(:finding_description) { '# Finding' }

    it 'returns finding information' do
      rendered_markdown = '<h1 data-sourcepos="1:1-1:15" dir="auto">&#x000A;<a id="user-content-vulnerability" class="anchor" href="#vulnerability" aria-hidden="true"></a>Vulnerability</h1>'

      expect(subject.first['description']).to eq('# Vulnerability')
      expect(subject.first['descriptionHtml']).to eq(rendered_markdown)
    end
  end
end
