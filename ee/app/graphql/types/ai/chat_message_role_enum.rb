# frozen_string_literal: true

module Types
  module Ai
    class ChatMessageRoleEnum < BaseEnum
      graphql_name 'AiChatMessageRole'
      description 'Roles to filter in chat message.'

      ::Gitlab::Llm::Cache::ALLOWED_ROLES.each do |role|
        value role.upcase, description: "Filter only #{role} messages.", value: role
      end
    end
  end
end
