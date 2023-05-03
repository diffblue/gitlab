# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class GenerateDescription
          def self.get_options(user_content)
            system_content = <<-TEMPLATE
            Please rewrite the content below using the given template format.

            Ensure the rewritten content adheres to the template format provided. If no template is provided, use your best judgment on a format.
            TEMPLATE

            {
              messages: [
                { role: "system", content: system_content },
                { role: "user", content: user_content }
              ],
              temperature: 0.5
            }
          end
        end
      end
    end
  end
end
