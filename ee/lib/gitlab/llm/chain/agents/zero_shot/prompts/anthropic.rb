# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            ROLE_NAMES = {
              Llm::ChatMessage::ROLE_USER => 'Human',
              Llm::ChatMessage::ROLE_ASSISTANT => 'Assistant'
            }.freeze

            class Anthropic < Base
              def self.prompt(options)
                text = <<~PROMPT
                  #{ROLE_NAMES[Llm::ChatMessage::ROLE_USER]}: #{base_prompt(options)}
                PROMPT

                history = truncated_conversation(options[:conversation], Requests::Anthropic::PROMPT_SIZE - text.size)
                text = [history, text].join if history.present?

                Requests::Anthropic.prompt(text)
              end

              # Returns messages from previous conversation. To assure that overall prompt size is not too big,
              # we keep adding messages from most-recent to older until we reach overall prompt limit.
              def self.truncated_conversation(conversation, limit)
                return '' if conversation.blank?

                result = ''
                conversation.reverse_each do |message|
                  new_str = "#{ROLE_NAMES[message.role]}: #{message.content}\n\n#{result}"
                  break if limit < new_str.size

                  result = new_str
                end

                result
              end

              def self.current_code_prompt(blob)
                <<~PROMPT
                The current code file that user sees is #{blob.path} and has the following content:
                <content>
                #{blob.data}
                </content>\n
                PROMPT
              end
            end
          end
        end
      end
    end
  end
end
