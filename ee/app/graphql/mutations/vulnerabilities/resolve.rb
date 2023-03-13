# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Resolve < BaseMutation
      graphql_name 'VulnerabilityResolve'

      authorize :admin_vulnerability

      field :vulnerability, Types::VulnerabilityType,
            null: true,
            description: 'Vulnerability after state change.'

      argument :id,
               ::Types::GlobalIDType[::Vulnerability],
               required: true,
               description: 'ID of the vulnerability to be resolved.'

      argument :comment,
               GraphQL::Types::String,
               required: false,
               description: 'Comment why vulnerability was reverted to detected (max. 50 000 characters).'

      def resolve(id:, comment: nil)
        vulnerability = authorized_find!(id: id)
        result = resolve_vulnerability(vulnerability, comment)

        {
          vulnerability: result,
          errors: result.errors.full_messages || []
        }
      end

      private

      def resolve_vulnerability(vulnerability, comment)
        ::Vulnerabilities::ResolveService.new(current_user, vulnerability, comment).execute
      end

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
