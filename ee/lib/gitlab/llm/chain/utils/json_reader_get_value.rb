# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class JsonReaderGetValue < TextProcessing
          def self.handle_keys(input, data)
            keys = extract_keys(input)
            data.dig(*keys)
          end
        end
      end
    end
  end
end
