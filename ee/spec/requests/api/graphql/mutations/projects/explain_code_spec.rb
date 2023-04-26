# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'AiAction for Explain Code', feature_category: :source_code_management do
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }

  let(:messages) do
    [
      {
        role: 'system',
        content: 'You are a knowledgeable assistant explaining to an engineer'
      }, {
        role: 'user',
        content: 'A question that needs to be answered'
      }
    ]
  end

  let(:mutation) do
    params = { explain_code: { messages: messages, resource_id: project.to_gid } }

    graphql_mutation(:ai_action, params) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  before do
    stub_licensed_features(explain_code: true)
  end

  it 'successfully performs an explain code request' do
    expect(Llm::CompletionWorker).to receive(:perform_async).with(
      current_user.id, project.id, "Project", :explain_code, { markup_format: :raw, messages: messages }
    )

    post_graphql_mutation(mutation, current_user: current_user)

    expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
  end

  context 'when empty messages are passed' do
    let(:messages) { [] }

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(fresh_response_data['errors'][0]['message']).to eq("messages can't be blank")
    end
  end

  context 'when openai_experimentation feature flag is disabled' do
    before do
      stub_feature_flags(openai_experimentation: false)
    end

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(fresh_response_data['errors'][0]['message']).to eq("`openai_experimentation` feature flag is disabled.")
    end
  end
end
