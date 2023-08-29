# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying user AI messages', :clean_gitlab_redis_cache, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:external_issue) { create(:issue) }
  let_it_be(:external_issue_url) do
    project_issue_url(external_issue.project, external_issue)
  end

  let(:fields) do
    <<~GRAPHQL
      nodes {
        requestId
        content
        contentHtml
        role
        timestamp
        errors
      }
    GRAPHQL
  end

  let(:arguments) { { requestIds: 'uuid1' } }
  let(:query) { graphql_query_for('aiMessages', arguments, fields) }

  let(:response_content) do
    "response #{external_issue_url}+"
  end

  subject { graphql_data.dig('aiMessages', 'nodes') }

  before do
    ::Gitlab::Llm::Cache.new(user).add(request_id: 'uuid1', role: 'user', content: 'question 1')
    ::Gitlab::Llm::Cache.new(user).add(request_id: 'uuid1', role: 'assistant', content: response_content)
    # should not be included in response because it's for other user
    ::Gitlab::Llm::Cache.new(other_user).add(request_id: 'uuid1', role: 'user', content: 'question 2')
  end

  context 'when user is not logged in' do
    let(:current_user) { nil }

    it 'returns an empty array' do
      post_graphql(query, current_user: current_user)

      expect(subject).to be_empty
    end
  end

  context 'when user is logged in' do
    let(:current_user) { user }

    it 'returns user messages', :freeze_time do
      post_graphql(query, current_user: current_user)

      expect(subject).to eq([
        { 'requestId' => 'uuid1',
          'content' => 'question 1',
          'contentHtml' => '<p data-sourcepos="1:1-1:10" dir="auto">question 1</p>',
          'role' => 'USER',
          'errors' => [],
          'timestamp' => Time.current.iso8601 },
        { 'requestId' => 'uuid1',
          'content' => response_content,
          'contentHtml' => "<p data-sourcepos=\"1:1-1:#{response_content.size}\" dir=\"auto\">response " \
                           "<a href=\"#{external_issue_url}+\">#{external_issue_url}+</a></p>",
          'role' => 'ASSISTANT',
          'errors' => [],
          'timestamp' => Time.current.iso8601 }
      ])
    end
  end
end
