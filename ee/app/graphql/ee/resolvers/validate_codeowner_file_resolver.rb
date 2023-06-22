# frozen_string_literal: true

module EE
  module Resolvers
    class ValidateCodeownerFileResolver < ::Resolvers::BaseResolver
      include ::Gitlab::Graphql::Authorize::AuthorizeResource

      type ::EE::Types::Repository::CodeOwnerValidationType, null: true
      authorize :read_code
      calls_gitaly!

      argument :ref, GraphQL::Types::String,
        required: false,
        description: "Ref where code owners file needs to be  checked. Defaults to the repository's default branch."

      alias_method :repository, :object

      def resolve(ref: nil)
        loader = ::Gitlab::CodeOwners::Loader.new(
          repository.project,
          ref || repository.root_ref
        )

        return if loader.empty_code_owners? # return nil if code owner is not present or empty

        file_errors = loader.file_errors

        response = {
          total: file_errors.size
        }

        response[:validation_errors] = file_errors.group_by(&:message).map do |message, err_group|
          {
            code: message.to_s,
            lines: err_group.map(&:line_number)
          }
        end

        response
      end
    end
  end
end
