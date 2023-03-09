# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Confirm < BaseMutation
      graphql_name 'VulnerabilityConfirm'

      authorize :admin_vulnerability

      field :vulnerability, Types::VulnerabilityType,
            null: true,
            description: 'Vulnerability after state change.'

      argument :id,
               ::Types::GlobalIDType[::Vulnerability],
               required: true,
               description: 'ID of the vulnerability to be confirmed.'

      argument :comment,
               GraphQL::Types::String,
               required: false,
               description: 'Comment why vulnerability was marked as confirmed (max. 50 000 characters).'

      def resolve(id:, comment: nil)
        vulnerability = authorized_find!(id: id)
        result = confirm_vulnerability(vulnerability, comment)

        {
          vulnerability: result,
          errors: result.errors.full_messages || []
        }
      end

      private

      def confirm_vulnerability(vulnerability, comment)
        ::Vulnerabilities::ConfirmService.new(current_user, vulnerability, comment).execute
      end

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
