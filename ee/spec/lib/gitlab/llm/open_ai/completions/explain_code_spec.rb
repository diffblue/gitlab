# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Completions::ExplainCode, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:content) { "some random content" }
  let(:template_class) { ::Gitlab::Llm::OpenAi::Templates::ExplainCode }
  let(:tracking_context) { { request_id: "uuid" } }
  let(:options) do
    {
      messages: [{
        role: 'system',
        content: 'You are a knowledgeable assistant explaining to an engineer'
      }, {
        role: 'user',
        content: content
      }]
    }
  end

  let(:ai_template) do
    {
      messages: options[:messages],
      max_tokens: 300,
      temperature: 0.3
    }
  end

  let(:ai_response) do
    {
      choices: [
        {
          text: "some ai response text"
        }
      ]
    }.to_json
  end

  let(:params) { { request_id: 'uuid' } }

  subject(:explain_code) { described_class.new(template_class, params).execute(user, project, options) }

  describe "#execute" do
    it 'performs an openai request' do
      expect_next_instance_of(Gitlab::Llm::OpenAi::Client, user, tracking_context: tracking_context) do |instance|
        expect(instance).to receive(:chat).with(content: nil, **ai_template).and_return(ai_response)
      end

      response_modifier = double
      response_service = double
      params = [user, project, response_modifier, { options: { request_id: 'uuid' } }]

      expect(Gitlab::Llm::OpenAi::ResponseModifiers::Chat).to receive(:new).with(ai_response).and_return(
        response_modifier
      )
      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
        response_service
      )
      expect(response_service).to receive(:execute)

      explain_code
    end
  end
end
