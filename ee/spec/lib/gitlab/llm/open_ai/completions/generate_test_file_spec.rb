# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Completions::GenerateTestFile, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:template_class) { ::Gitlab::Llm::Templates::GenerateTestFile }
  let(:ai_template) { 'something' }
  let(:content) { "some ai response text" }
  let(:ai_response) do
    {
      choices: [
        {
          message: {
            content: content
          }
        }
      ]
    }.to_json
  end

  subject(:generate_test_file) do
    described_class.new(template_class).execute(user, merge_request, { file_path: 'index.js' })
  end

  before do
    group.namespace_settings.update!(third_party_ai_features_enabled: true)
  end

  describe "#execute" do
    context 'with valid params' do
      it 'performs the OpenAI request' do
        expect_next_instance_of(::Gitlab::Llm::OpenAi::Completions::GenerateTestFile) do |completion_service|
          expect(completion_service).to receive(:execute).with(user, merge_request, { file_path: 'index.js' })
            .and_call_original
        end

        expect_next_instance_of(::Gitlab::Llm::Templates::GenerateTestFile) do |template|
          expect(template).to receive(:to_prompt).and_return(ai_template)
        end

        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |instance|
          params = { content: 'something', max_tokens: 1000, moderated: true }
          allow(instance).to receive(:chat).with(params).and_return(ai_response)
        end

        uuid = 'uuid'

        expect(SecureRandom).to receive(:uuid).twice.and_return(uuid)

        data = {
          id: uuid,
          model_name: 'MergeRequest',
          content: content,
          request_id: nil,
          role: 'assistant',
          timestamp: an_instance_of(ActiveSupport::TimeWithZone),
          errors: []
        }

        expect(GraphqlTriggers).to receive(:ai_completion_response).with(
          user.to_global_id, merge_request.to_global_id, data
        )

        generate_test_file
      end
    end
  end
end
