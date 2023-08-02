# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::Completions::ExplainCode, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:response_body) { 'consequent response' }
  let(:template_class) { ::Gitlab::Llm::VertexAi::Templates::ExplainCode }
  let(:options) do
    {
      messages: [{
        'role' => 'system',
        'content' => 'You are a knowledgeable assistant explaining to an engineer'
      }, {
        'role' => 'user',
        'content' => 'some initial request'
      }, {
        'role' => 'assistant',
        'content' => 'some response'
      }, {
        'role' => 'user',
        'content' => 'consequent request'
      }]
    }
  end

  let(:ai_template) do
    {
      instances: [
        messages: [{
          'author' => 'user',
          'content' => "You are a knowledgeable assistant explaining to an engineer\nsome initial request"
        }, {
          'author' => 'content',
          'content' => 'some response'
        }, {
          'author' => 'user',
          'content' => 'consequent request'
        }]
      ],
      parameters: {
        maxOutputTokens: 300,
        temperature: 0.3,
        topK: 40,
        topP: 0.95
      }
    }
  end

  let(:ai_response) do
    {
      'predictions' => [
        {
          "candidates" => [
            {
              "content" => response_body,
              "author" => "assistant"
            }
          ]
        }
      ]
    }.to_json
  end

  let(:params) { { request_id: 'uuid' } }

  subject(:explain_code) { described_class.new(template_class, params).execute(user, project, options) }

  describe "#execute" do
    it 'performs an Vertex AI request' do
      expect_next_instance_of(Gitlab::Llm::VertexAi::Client, user) do |instance|
        expect(instance).to receive(:chat).with(content: nil, **ai_template).and_return(ai_response)
      end

      params = [user, project, anything, { options: { request_id: 'uuid' } }]

      expect(Gitlab::Llm::VertexAi::ResponseModifiers::Predictions).to receive(:new).with(ai_response).and_call_original
      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_call_original
      expect(GraphqlTriggers).to receive(:ai_completion_response) do |user_id, resource_id, data|
        expect(user_id).to eq(user.to_global_id)
        expect(resource_id).to eq(project.to_global_id)
        expect(data[:content]).to eq(response_body)
      end

      explain_code
    end
  end
end
