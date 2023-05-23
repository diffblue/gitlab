# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class TextProcessing
          STOP_REGEX = /Observation:/

          def self.text_before_stop_word(text)
            text.split(STOP_REGEX, 2).first
          end
        end
      end
    end
  end
end
