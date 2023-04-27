# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module ResponseModifiers
        class TanukiBot
          CONTENT_ID_FIELD = 'ATTRS'
          CONTENT_ID_REGEX = /CNT-IDX-(?<id>\d+)/

          def execute(ai_response)
            text = ai_response&.dig(:choices, 0, :text)

            return unless text

            output = text.split("#{CONTENT_ID_FIELD}:")
            msg = output[0].strip
            ids = output[1].scan(CONTENT_ID_REGEX).flatten.map(&:to_i)
            documents = ::Embedding::TanukiBotMvc.where(id: ids)
            sources = documents.pluck(:metadata).uniq

            {
              msg: msg,
              sources: sources
            }
          end
        end
      end
    end
  end
end
