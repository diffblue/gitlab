# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class TextProcessing
          STOP_REGEX = /Observation:/

          def self.text_before_stop_word(text)
            text.split(STOP_REGEX).first
          end

          def self.extract_keys(input)
            input.scan(/\[.*?\]/)
                 .map { |x| x[1..-2].delete("\"").delete("'") }
                 .map { |x| x =~ /^(\d)+$/ ? Integer(x) : x }
          end
        end
      end
    end
  end
end
