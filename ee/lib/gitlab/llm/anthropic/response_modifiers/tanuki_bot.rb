# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      module ResponseModifiers
        class TanukiBot < Gitlab::Llm::BaseResponseModifier
          include Gitlab::Utils::StrongMemoize

          CONTENT_ID_FIELD = 'ATTRS'
          CONTENT_ID_REGEX = /CNT-IDX-(?<id>\d+)/
          NO_ANSWER_REGEX = /i do.*n.+know/i

          def response_body
            parsed_response && parsed_response[:content]
          end

          def extras
            return parsed_response[:extras] if parsed_response

            super
          end

          def errors
            @errors ||= [ai_response&.dig(:error)].compact
          end

          private

          def parsed_response
            text = ai_response&.dig(:completion).to_s.strip

            return unless text.present?

            output = text.split("#{CONTENT_ID_FIELD}:")
            msg = output[0].strip

            sources = if msg.match(NO_ANSWER_REGEX)
                        []
                      else
                        ids = output[1].scan(CONTENT_ID_REGEX).flatten.map(&:to_i)
                        documents = ::Embedding::TanukiBotMvc.id_in(ids).select(:url, :metadata)
                        documents.map do |doc|
                          { source_url: doc.url }.merge(doc.metadata)
                        end.uniq
                      end

            {
              content: msg,
              extras: {
                sources: sources
              }
            }
          end
          strong_memoize_attr :parsed_response
        end
      end
    end
  end
end
