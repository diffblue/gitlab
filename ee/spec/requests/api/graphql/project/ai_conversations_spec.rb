# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting ai conversations related to a project', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:message) { create(:message, project: project, user: project.owner, async_errors: ['my_error']) }

  let(:current_user) { project.owner }

  let(:query_body) do
    <<~QUERY
     aiConversations {
       ciConfigMessages {
         nodes {
           id,
           content,
           role,
           errors,
           isFetching
         }
       }
     }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_body
    )
  end

  context 'with messages that should not be returned' do
    before do
      create(:message, project: project, user: create(:user), async_errors: ['my_error'])
      create(:message, project: create(:project), user: current_user, async_errors: ['my_error'])
    end

    it 'returns only the relevant messages' do
      post_graphql(query, current_user: current_user)

      messages = graphql_data.dig('project', 'aiConversations', 'ciConfigMessages', 'nodes')

      expect(messages.size).to eq(1)
      expect(messages.first["id"]).to eq(message.to_global_id.to_s)
    end
  end
end
