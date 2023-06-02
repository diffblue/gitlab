# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::Completions::FillInMergeRequestTemplate, feature_category: :code_review_workflow do
  let(:prompt_class) { Gitlab::Llm::Templates::FillInMergeRequestTemplate }
  let(:options) { { request_id: 'uuid' } }
  let(:response_modifier) { double }
  let(:response_service) { double }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:params) { [user, project, response_modifier, { options: { request_id: 'uuid' } }] }

  subject { described_class.new(prompt_class, options) }

  describe '#execute' do
    context 'when the text client returns a successful response' do
      let(:example_answer) { "AI filled in template" }

      let(:example_response) do
        {
          "predictions" => [
            {
              "content" => example_answer,
              "safetyAttributes" => {
                "categories" => ["Violent"],
                "scores" => [0.4000000059604645],
                "blocked" => false
              }
            }
          ]
        }
      end

      before do
        allow_next_instance_of(Gitlab::Llm::VertexAi::Client) do |client|
          allow(client).to receive(:text).and_return(example_response.to_json)
        end
      end

      it 'publishes the content from the AI response' do
        expect(::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions)
          .to receive(:new)
          .with(example_response.to_json)
          .and_return(response_modifier)

        expect(::Gitlab::Llm::GraphqlSubscriptionResponseService)
          .to receive(:new)
          .with(*params)
          .and_return(response_service)

        expect(response_service).to receive(:execute)

        subject.execute(user, project, options)
      end
    end

    context 'when the text client returns an unsuccessful response' do
      let(:error) { { error: 'Error' } }

      before do
        allow_next_instance_of(Gitlab::Llm::VertexAi::Client) do |client|
          allow(client).to receive(:text).and_return(error.to_json)
        end
      end

      it 'publishes the error to the graphql subscription' do
        expect(::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions)
          .to receive(:new)
          .with(error.to_json)
          .and_return(response_modifier)

        expect(::Gitlab::Llm::GraphqlSubscriptionResponseService)
          .to receive(:new)
          .with(*params)
          .and_return(response_service)

        expect(response_service).to receive(:execute)

        subject.execute(user, project, options)
      end
    end
  end
end
