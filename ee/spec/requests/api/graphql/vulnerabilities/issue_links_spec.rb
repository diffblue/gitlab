# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.issueLinks', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }
  let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project) }
  let_it_be(:created_issue) { create(:issue, project: project) }
  let_it_be(:related_issue) { create(:issue, project: project) }
  let_it_be(:related_issue_link) { create(:vulnerabilities_issue_link, :related, vulnerability: vulnerability, issue: related_issue) }
  let_it_be(:created_issue_link) { create(:vulnerabilities_issue_link, :created, vulnerability: vulnerability, issue: created_issue) }

  before do
    project.add_developer(user)

    stub_licensed_features(security_dashboard: true)
  end

  context 'when invalid linkType argument is provided' do
    it 'errors with a string' do
      query_issue_links('"created"')

      expect(graphql_errors).to include(a_hash_including('message' => "Argument 'linkType' on Field 'issueLinks' has an invalid value (\"created\"). Expected type 'VulnerabilityIssueLinkType'."))
    end

    it 'errors with a number' do
      query_issue_links(1)

      expect(graphql_errors).to include(a_hash_including('message' => "Argument 'linkType' on Field 'issueLinks' has an invalid value (1). Expected type 'VulnerabilityIssueLinkType'."))
    end

    it 'errors with lowercased `created`' do
      query_issue_links('created')

      expect(graphql_errors).to include(a_hash_including('message' => "Argument 'linkType' on Field 'issueLinks' has an invalid value (created). Expected type 'VulnerabilityIssueLinkType'."))
    end

    it 'errors with lowercased `related`' do
      query_issue_links('related')

      expect(graphql_errors).to include(a_hash_including('message' => "Argument 'linkType' on Field 'issueLinks' has an invalid value (related). Expected type 'VulnerabilityIssueLinkType'."))
    end
  end

  context 'when valid linkType argument is provided' do
    it 'returns a list of VulnerabilityIssueLink with `CREATED` linkType' do
      query_issue_links('CREATED')

      expect_issue_links_response(created_issue_link)
    end

    it 'returns a list of VulnerabilityIssueLink with `RELATED` linkType' do
      query_issue_links('RELATED')

      expect_issue_links_response(related_issue_link)
    end
  end

  context 'when no arguments are provided' do
    it 'returns a list of all VulnerabilityIssueLink' do
      query_issue_links

      expect_issue_links_response(related_issue_link, created_issue_link)
    end
  end

  describe 'loading issue links in batch' do
    before do
      create(:vulnerability, :with_finding, project: project)
    end

    it 'does not cause N+1 query issue' do
      query_issue_links # Calling this the first time issues more queries

      # 1) Select personal access tokens
      # 2) Savepoint
      # 3) Insert into personal access tokens
      # 4) Release savepoint
      # 5) Select personal access tokens
      # 6) Select geo nodes
      # 7) Update personal access tokens(last used at)
      # 8) Select user
      # 9) Authorization check
      # 10) Select vulnerability_reads
      # 11) Select vulnerabilities
      # 12) Select project
      # 13) Select route
      # 14) Select vulnerability occurrences
      # 15) Select vulnerability scanners
      # 16) Select vulnerability identifiers join table
      # 17) Select vulnerability identifiers
      # 18) Select namespace
      # 19) Authorization check
      # 20) Select issue links
      # 21) Select issues
      # 22) Select issue project
      # 23) Select issue user
      # 24) Select project features
      expect { query_issue_links }.not_to exceed_query_limit(24)
    end
  end

  def query_issue_links(link_type = nil)
    query = graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, create_fields(link_type)))
    post_graphql(query, current_user: user)
  end

  def create_fields(link_type)
    if link_type.nil?
      <<~QUERY
        issueLinks {
          nodes {
            id
          }
        }
      QUERY
    else
      <<~QUERY
        issueLinks (linkType: #{link_type}) {
          nodes {
            id
          }
        }
      QUERY
    end
  end

  def expect_issue_links_response(*issue_links)
    actual_issue_links = graphql_data['vulnerabilities']['nodes'].map do |vulnerability|
      vulnerability["issueLinks"]["nodes"].map { |issue_link| issue_link['id'] }
    end
    expected_issue_links = issue_links.map { |issue_link| issue_link.to_global_id.to_s }

    expect(actual_issue_links.flatten).to contain_exactly(*expected_issue_links)
    expect(graphql_errors).to be_nil
  end
end
