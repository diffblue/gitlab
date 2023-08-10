# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'AiAction for chat', :saas, feature_category: :shared do
  include GraphqlHelpers

  let_it_be_with_reload(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }
  let_it_be(:resource) { create(:issue, project: project) }
  let(:resource_id) { resource.to_gid }

  let(:mutation) do
    params = { chat: { resource_id: resource_id, content: "summarize" } }

    graphql_mutation(:ai_action, params) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  before do
    group.add_developer(current_user)
  end

  include_context 'with ai features enabled for group'

  context 'when resource is nil' do
    let(:resource_id) { nil }

    it 'successfully performs a chat request' do
      expect(Llm::CompletionWorker).to receive(:perform_async).with(
        current_user.id, nil, nil, :chat, {
          content: "summarize", markup_format: :raw, request_id: an_instance_of(String),
          cache_response: true, emit_user_messages: true
        }
      )

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when resource is an issue' do
    it 'successfully performs a request' do
      expect(Llm::CompletionWorker).to receive(:perform_async).with(
        current_user.id, resource.id, "Issue", :chat, {
          content: "summarize", markup_format: :raw, request_id: an_instance_of(String),
          cache_response: true, emit_user_messages: true
        }
      )

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
    end
  end

  context 'when resource is a user' do
    let_it_be_with_reload(:resource) { current_user }

    it 'successfully performs a request' do
      expect(Llm::CompletionWorker).to receive(:perform_async).with(
        current_user.id, current_user.id, "User", :chat, {
          content: "summarize", markup_format: :raw, request_id: an_instance_of(String),
          cache_response: true, emit_user_messages: true
        }
      )

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
    end
  end

  context 'when gitlab_duo feature flag is disabled' do
    before do
      stub_feature_flags(gitlab_duo: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when openai_experimentation feature flag is disabled' do
    before do
      stub_feature_flags(openai_experimentation: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end
end
