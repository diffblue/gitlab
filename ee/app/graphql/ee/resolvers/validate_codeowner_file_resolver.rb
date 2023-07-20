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

      argument :path, GraphQL::Types::String,
        required: false,
        description: "Path of a file called CODEOWNERS that should be validated. Default to file in use."

      alias_method :repository, :object

      def resolve(ref: nil, path: nil)
        requested_ref = ref.presence || repository.root_ref
        requested_path = fetch_code_owners_path(requested_ref, path)

        return unless requested_path

        file_name = File.basename(requested_path)
        return if file_name != ::Gitlab::CodeOwners::FILE_NAME

        blob = repository.blobs_at([[requested_ref, requested_path]]).first

        return if blob.nil?

        code_owners_file = ::Gitlab::CodeOwners::File.new(blob)

        code_owners_file.valid?

        file_errors = code_owners_file.errors

        response = { total: file_errors.size }

        response[:validation_errors] = file_errors.group_by(&:message).map do |message, err_group|
          {
            code: message.to_s,
            lines: err_group.map(&:line_number)
          }
        end

        response
      end

      private

      def fetch_code_owners_path(ref, path)
        return path if path.present?

        loader = ::Gitlab::CodeOwners::Loader.new(
          repository.project,
          ref
        )

        loader.code_owners_path
      end
    end
  end
end
