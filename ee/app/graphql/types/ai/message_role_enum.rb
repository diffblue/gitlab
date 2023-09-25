# frozen_string_literal: true

module Types
  module Ai
    class MessageRoleEnum < BaseEnum
      graphql_name 'AiMessageRole'
      description 'Possible message roles for AI features.'

      ::Gitlab::Llm::ChatMessage::ALLOWED_ROLES.each do |role|
        value role.upcase, description: "#{role} message.", value: role
      end
    end
  end
end
