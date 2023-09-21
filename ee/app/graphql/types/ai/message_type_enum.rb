# frozen_string_literal: true

module Types
  module Ai
    class MessageTypeEnum < BaseEnum
      graphql_name 'AiMessageType'
      description 'Types of messages returned from AI features.'

      value 'TOOL', description: 'Tool selection message.', value: 'tool'
    end
  end
end
