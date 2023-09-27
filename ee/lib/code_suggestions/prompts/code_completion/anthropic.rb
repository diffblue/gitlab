# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeCompletion
      class Anthropic < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 2

        def request_params
          {
            prompt: prompt,
            prompt_version: GATEWAY_PROMPT_VERSION
          }
        end

        private

        def prompt
          <<~PROMPT
            Human: Here is a content of a file '#{file_path_info}' written in #{language} enclosed
            in <code></code> tags. Review the code to understand existing logic and format, then return
            a valid code enclosed in <result></result> tags which can be added instead of
            <complete> tag. Do not add other code.

            <code>
              #{prefix}<complete>
              #{suffix}
            </code>

            Assistant:
          PROMPT
        end
      end
    end
  end
end
