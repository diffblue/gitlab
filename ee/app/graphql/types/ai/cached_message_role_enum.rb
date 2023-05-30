# frozen_string_literal: true

module Types
  module Ai
    class CachedMessageRoleEnum < BaseEnum
      graphql_name 'AiCachedMessageRole'
      description 'Roles to filter in chat message.'

      ::Gitlab::Llm::Cache::ALLOWED_ROLES.each do |role|
        value role.upcase, description: "Filter only #{role} messages.", value: role
      end
    end
  end
end
