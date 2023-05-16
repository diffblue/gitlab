# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Llm::GenerateConfigService, feature_category: :continuous_integration do
  let_it_be(:existing_user_content) { 'how can I test a python application?' }
  let_it_be(:user_prompt) { 'what if I wanted to use pytest?' }
  let_it_be(:example_response_content) do
    <<-YAML
    test:
    stage: test
    script: pytest .
    YAML
  end

  let_it_be(:user)          { create(:user) }
  let_it_be(:project)       { create(:project, creator: user) }
  let_it_be(:existing_user_message) { create(:message, content: existing_user_content, user: user, project: project) }
  let_it_be(:existing_ai_message) do
    create(:message, :ai, content: example_response_content, user: user, project: project)
  end

  let_it_be(:user_message) { create(:message, content: user_prompt, user: user, project: project) }
  let_it_be(:blank_ai_message) { create(:message, :ai, user: user, project: project) }

  let_it_be(:example_response) do
    {
      "id" => "chatcmpl-72mX77BBH9Hgj196u7BDhKyCTiXxL",
      "object" => "chat.completion",
      "created" => 1680897573,
      "model" => "gpt-3.5-turbo-0301",
      "usage" => { "prompt_tokens" => 3447, "completion_tokens" => 57, "total_tokens" => 3504 },
      "choices" =>
        [{
          "message" => { "role" => "assistant", "content" => example_response_content },
          "finish_reason" => "stop",
          "index" => 0
        }]
    }.to_json
  end

  let(:response_double) { instance_double(HTTParty::Response, parsed_response: example_response) }
  let(:errored_response_double) { instance_double(HTTParty::Response, parsed_response: { error: "true" }) }

  let(:service) do
    described_class.new(ai_message: blank_ai_message)
  end

  describe '#execute' do
    subject { service.execute }

    it 'gets the ai response and persists it' do
      expect_next_instance_of(Gitlab::Llm::OpenAi::Client, user) do |instance|
        expect(instance).to receive(:messages_chat).with(messages:
          [
            { role: Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE, content: service.send(:gitlab_prompt) },
            { role: user_message.role, content: existing_user_content },
            { role: blank_ai_message.role, content: example_response_content },
            { role: user_message.role, content: user_prompt }
          ], temperature: 0.3
        ).and_return(example_response)
      end

      subject
    end

    context 'when over content limit' do
      it 'deletes content' do
        create_list(:message, 20, content: 'a' * 1000, user: user, project: project)

        expect_next_instance_of(Gitlab::Llm::OpenAi::Client, user) do |instance|
          expect(instance).to receive(:messages_chat).and_return(example_response)
        end

        messages = Ci::Editor::AiConversation::Message.belonging_to(project, user)
        expect(messages.size).to be 24

        subject

        messages2 = Ci::Editor::AiConversation::Message.belonging_to(project, user)
        expect(messages2.size).to be 14
      end
    end
  end
end
