# frozen_string_literal: true

module EE
  module Types
    module RepositoryType
      extend ActiveSupport::Concern

      prepended do
        present_using RepositoryPresenter

        field :code_owners_path, GraphQL::Types::String,
          null: true,
          calls_gitaly: true,
          description: 'Path to CODEOWNERS file in a ref.' do
            argument :ref, GraphQL::Types::String, required: false, description: 'Name of the ref.'
          end

        field :validate_codeowner_file, Types::Repository::CodeOwnerValidationType,
          null: true,
          calls_gitaly: true,
          description: 'Shows linting errors in the CODEOWNER file of the repository.',
          resolver: EE::Resolvers::ValidateCodeownerFileResolver
      end
    end
  end
end
