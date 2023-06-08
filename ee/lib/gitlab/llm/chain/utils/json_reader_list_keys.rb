# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class JsonReaderListKeys < TextProcessing
          def self.handle_keys(input, data)
            keys = extract_keys(input)
            return data.keys if keys.blank?

            value = data

            keys.each do |key|
              value = value[key]
              unless value.respond_to?(:keys)
                break "ValueError: Value at path `#{input}` is not a Hash, try to use `JsonReaderGetValue`
                  to get the value directly."
              end

              value.keys.to_s
            end
          end
        end
      end
    end
  end
end
