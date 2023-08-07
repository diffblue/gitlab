# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Requests
        class Base
          def self.prompt(prompt, options: {})
            { prompt: prompt, options: options }
          end
        end
      end
    end
  end
end
