# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class ExplainCode < Gitlab::Llm::Completions::Base
          def execute(user, project, options)
            options = ai_prompt_class.get_options(options[:messages])

            ai_response = Gitlab::Llm::OpenAi::Client.new(user).chat(content: nil, **options)
            response_modifier = Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new(ai_response)

            ::Gitlab::Llm::GraphqlSubscriptionResponseService
              .new(user, project, response_modifier, options: { request_id: params[:request_id] })
              .execute
          end
        end
      end
    end
  end
end
