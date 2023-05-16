# frozen_string_literal: true

FactoryBot.define do
  factory :message, class: 'Ci::Editor::AiConversation::Message' do
    project
    user
    role { Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE }
    content { nil }
    async_errors { [] }
  end

  trait :ai do
    role { Gitlab::Llm::OpenAi::Options::AI_ROLE }
  end
end
