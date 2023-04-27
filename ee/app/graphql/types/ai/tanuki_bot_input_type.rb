# frozen_string_literal: true

module Types
  module Ai
    class TanukiBotInputType < BaseMethodInputType
      graphql_name 'AiTanukiBotInput'

      argument :question, GraphQL::Types::String,
        required: true,
        validates: { allow_blank: false },
        description: 'GitLab documentation question for AI to answer.'
    end
  end
end
