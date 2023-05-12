# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Completions::GenerateDescription, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:template_class) { ::Gitlab::Llm::OpenAi::Templates::GenerateDescription }
  let(:uuid) { 'uuid' }
  let(:ai_options) do
    {
      messages: [
        { role: "system", content: "You are a helpful assistant that autocompletes issue descriptions." },
        { role: "user", content: "Some content" }
      ],
      temperature: 0.2,
      description_template_name: "Bug"
    }
  end

  let(:ai_response) do
    {
      choices: [
        {
          message: {
            content: "some ai response text"
          }
        }
      ]
    }.to_json
  end

  RSpec.shared_examples 'performs completion' do
    it 'gets the right template options and calls the openai client' do
      expect_next_instance_of(::Gitlab::Llm::OpenAi::Completions::GenerateDescription) do |completion_service|
        expect(completion_service).to receive(:execute).with(user, issuable, ai_options).and_call_original
      end

      expect(Gitlab::Llm::OpenAi::Templates::GenerateDescription).to receive(:get_options)
        .and_return(ai_options)

      expect_next_instance_of(Gitlab::Llm::OpenAi::Client) do |instance|
        expect(instance).to receive(:chat).with(content: nil, **ai_options).and_return(ai_response)
      end

      response_modifier = double
      response_service = double
      params = [user, issuable, response_modifier, { options: { request_id: uuid } }]

      expect(Gitlab::Llm::OpenAi::ResponseModifiers::Chat).to receive(:new).with(ai_response).and_return(
        response_modifier
      )

      expect(::Gitlab::Llm::GraphqlSubscriptionResponseService).to receive(:new).with(*params).and_return(
        response_service
      )
      expect(response_service).to receive(:execute)

      generate_description
    end
  end

  subject(:generate_description) do
    described_class.new(template_class, { request_id: uuid }).execute(user, issuable, ai_options)
  end

  describe "#execute" do
    context 'with invalid params' do
      context 'without user' do
        let(:user) { nil }
        let_it_be(:issuable) { double }

        specify { expect(generate_description).to be_nil }
      end

      context 'without issuable' do
        let_it_be(:issuable) { nil }

        specify { expect(generate_description).to be_nil }
      end

      context 'with invalid prompt class' do
        let_it_be(:issuable) { create(:issue, project: project) }

        let(:template_class) { Issue }

        specify { expect { generate_description }.to raise_error(NoMethodError) }
      end
    end

    context 'with valid params' do
      context 'for an issue' do
        let_it_be(:issuable) { create(:issue, project: project) }

        it_behaves_like 'performs completion'

        context 'with non-existent description template' do
          let_it_be(:issuable) { create(:issue, project: project) }

          before do
            ai_options[:description_template_name] = "non-existent"
          end

          it_behaves_like 'performs completion'
        end
      end

      context 'for a work item' do
        let_it_be(:issuable) { create(:work_item, :task, project: project) }

        it_behaves_like 'performs completion'
      end

      context 'for a merge request' do
        let_it_be(:issuable) { create(:merge_request, source_project: project) }

        it_behaves_like 'performs completion'
      end

      context 'for an epic' do
        let_it_be(:issuable) { create(:epic) }

        it_behaves_like 'performs completion'
      end
    end
  end
end
