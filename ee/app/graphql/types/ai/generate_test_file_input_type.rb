# frozen_string_literal: true

module Types
  module Ai
    class GenerateTestFileInputType < BaseMethodInputType
      graphql_name 'GenerateTestFileInput'

      argument :file_path, GraphQL::Types::String,
        required: true,
        validates: { allow_blank: false },
        description: 'File path to generate test files for.'
    end
  end
end
