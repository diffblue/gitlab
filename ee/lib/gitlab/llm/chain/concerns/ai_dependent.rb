# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Concerns
        module AiDependent
          def prompt
            return { prompt: base_prompt } unless provider_prompt_class

            provider_prompt_class.prompt(options)
          end

          def request
            logger.debug(message: "Prompt", class: self.class.to_s, content: prompt)
            ai_request.request(prompt)
          end

          private

          def ai_request
            context.ai_request
          end

          def provider_prompt_class
            ai_provider_name = ai_request.class.name.demodulize.underscore.to_sym

            self.class::PROVIDER_PROMPT_CLASSES[ai_provider_name]
          end

          def base_prompt
            raise NotImplementedError
          end
        end
      end
    end
  end
end
