# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying user AI messages', :clean_gitlab_redis_cache, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:fields) do
    <<~GRAPHQL
      nodes {
        requestId
        content
        role
        timestamp
        errors
      }
    GRAPHQL
  end

  let(:arguments) { { requestIds: 'uuid1' } }
  let(:query) { graphql_query_for('aiMessages', arguments, fields) }

  subject { graphql_data.dig('aiMessages', 'nodes') }

  before do
    ::Gitlab::Llm::Cache.new(user).add(request_id: 'uuid1', role: 'user')
    ::Gitlab::Llm::Cache.new(user).add(request_id: 'uuid1', role: 'assistant', content: 'response')
    # should not be included in response because it's for other user
    ::Gitlab::Llm::Cache.new(other_user).add(request_id: 'uuid1', role: 'user')
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
        { 'requestId' => 'uuid1', 'content' => nil, 'role' => 'USER', 'errors' => [],
          'timestamp' => Time.current.iso8601 },
        { 'requestId' => 'uuid1', 'content' => 'response', 'role' => 'ASSISTANT', 'errors' => [],
          'timestamp' => Time.current.iso8601 }
      ])
    end

    context 'when ai_redis_cache is disabled' do
      before do
        stub_feature_flags(ai_redis_cache: false)
      end

      it 'returns an empty array' do
        post_graphql(query, current_user: current_user)

        expect(subject).to be_empty
      end
    end
  end
end
