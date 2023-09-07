# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    module CodeGeneration
      class FromComment < CodeSuggestions::Tasks::Base
        extend ::Gitlab::Utils::Override

        GATEWAY_PROMPT_VERSION = 2

        override :endpoint_name
        def endpoint_name
          'generations'
        end

        override :body
        def body
          params.merge(
            prompt_version: GATEWAY_PROMPT_VERSION,
            prompt: prompt
          ).to_json
        end

        private

        def file_name
          params.dig('current_file', 'file_name').to_s
        end

        def prompt
          extension = File.extname(file_name).delete_prefix('.')

          <<~PROMPT
            ```#{extension}
            #{prefix}
            ```
          PROMPT
        end
      end
    end
  end
end
