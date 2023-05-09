# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'AiAction for Generate Test File', feature_category: :code_review_workflow do
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:file_path) { "files/js/commit.coffee" }

  let(:mutation) do
    params = { generate_test_file: { file_path: file_path, resource_id: merge_request.to_gid } }

    graphql_mutation(:ai_action, params) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  before do
    stub_licensed_features(generate_test_file: true)
    group.namespace_settings.update!(third_party_ai_features_enabled: true)
  end

  it 'successfully performs an explain code request' do
    expect(Llm::CompletionWorker).to receive(:perform_async).with(
      current_user.id, merge_request.id, "MergeRequest", :generate_test_file, {
        file_path: file_path, markup_format: :raw, request_id: an_instance_of(String)
      }
    )

    post_graphql_mutation(mutation, current_user: current_user)

    expect(graphql_mutation_response(:ai_action)['errors']).to eq([])
  end

  context 'when empty messages are passed' do
    let(:file_path) { "" }

    it 'returns nil' do
      expect(Llm::CompletionWorker).not_to receive(:perform_async)

      post_graphql_mutation(mutation, current_user: current_user)

      expect(fresh_response_data['errors'][0]['message']).to eq("filePath can't be blank")
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
