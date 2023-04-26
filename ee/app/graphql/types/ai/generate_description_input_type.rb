# frozen_string_literal: true

module Types
  module Ai
    class GenerateDescriptionInputType < BaseMethodInputType
      graphql_name 'AiGenerateDescriptionInput'

      argument :content, GraphQL::Types::String,
        required: true,
        description: 'Content of the message.'

      argument :description_template_name, GraphQL::Types::String,
        required: false,
        description: 'Name of the description template to use to generate message off of.'
    end
  end
end
