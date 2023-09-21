# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeGeneration
      class VertexAi < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 2

        def request_params
          {
            prompt_version: GATEWAY_PROMPT_VERSION,
            prompt: prompt
          }
        end

        private

        def prompt
          <<~PROMPT
            This is a task to write new #{language} code in a file '#{file_path_info}' based on a given description.
            #{existing_code_instruction}
            It is your task to write valid and working #{language} code.
            Only return in your response new code.
            #{existing_code_block}
            Create new code for the following description:
            `#{params[:instruction]}`
          PROMPT
        end

        def existing_code_instruction
          return unless params[:prefix].present?

          "You get first the already existing code file and then the description of the code that needs to be created."
        end

        def existing_code_block
          return unless params[:prefix].present?

          <<~CODE

            Already existing code:

            ```#{extension}
            #{params[:prefix]}
            ```
          CODE
        end
      end
    end
  end
end
