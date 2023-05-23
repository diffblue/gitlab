# frozen_string_literal: true

module Types
  module Ai
    class FillInMergeRequestTemplateInputType < BaseMethodInputType
      graphql_name 'AiFillInMergeRequestTemplateInput'

      argument :title, ::GraphQL::Types::String,
        required: true,
        description: 'Title of the merge request to be created.'

      argument :source_project_id, ::GraphQL::Types::ID,
        required: false,
        description: 'ID of the project where the changes are from.'

      argument :source_branch, ::GraphQL::Types::String,
        required: true,
        description: 'Source branch of the changes.'

      argument :target_branch, ::GraphQL::Types::String,
        required: true,
        description: 'Target branch of where the changes will be merged into.'

      argument :content, ::GraphQL::Types::String,
        required: true,
        description: 'Template content to fill in.'
    end
  end
end
