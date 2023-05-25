# frozen_string_literal: true

module Types
  module Ai
    class CachedMessageRoleEnum < BaseEnum
      graphql_name 'AiCachedMessageRole'
      description 'Roles to filter in chat message.'

      value 'USER', 'Filter only user messages.', value: 'user'
      value 'ASSISTANT', 'Filter only AI responses.', value: 'assistant'
    end
  end
end
