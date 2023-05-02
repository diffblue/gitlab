# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      class Options
        DEFAULT_TEMPERATURE = 0.7
        DEFAULT_MAX_TOKENS = 16

        AI_ROLE = "assistant"
        SYSTEM_ROLE = "system"
        DEFAULT_ROLE = "user"

        GPT_ROLES = [
          DEFAULT_ROLE,
          SYSTEM_ROLE,
          AI_ROLE
        ].freeze

        DEFAULT_MODELS = {
          chat: "gpt-3.5-turbo",
          completions: "text-davinci-003",
          edits: "text-davinci-edit-001",
          embeddings: "text-embedding-ada-002",
          moderations: "text-moderation-latest"
        }.freeze

        def chat(content:, **options)
          messages_chat(messages: [{ role: DEFAULT_ROLE, content: content }], **options)
        end

        def messages_chat(messages:, **options)
          raise ArgumentError unless messages.all? { |m| GPT_ROLES.member? m.with_indifferent_access[:role] }

          {
            model: DEFAULT_MODELS[:chat],
            messages: messages,
            temperature: DEFAULT_TEMPERATURE
          }.merge(options)
        end

        def completions(prompt:, **options)
          {
            model: DEFAULT_MODELS[:completions],
            prompt: prompt,
            max_tokens: DEFAULT_MAX_TOKENS
          }.merge(options)
        end

        def edits(input:, instruction:, **options)
          {
            model: DEFAULT_MODELS[:edits],
            input: input,
            instruction: instruction
          }.merge(options)
        end

        def embeddings(input:, **options)
          {
            model: DEFAULT_MODELS[:embeddings],
            input: input
          }.merge(options)
        end

        def moderations(input:, **options)
          {
            model: DEFAULT_MODELS[:moderations],
            input: input
          }.merge(options)
        end
      end
    end
  end
end
