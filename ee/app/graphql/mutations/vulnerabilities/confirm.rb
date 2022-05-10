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

      def resolve(id:)
        vulnerability = authorized_find!(id: id)
        result = confirm_vulnerability(vulnerability)

        {
          vulnerability: result,
          errors: result.errors.full_messages || []
        }
      end

      private

      def confirm_vulnerability(vulnerability)
        ::Vulnerabilities::ConfirmService.new(current_user, vulnerability).execute
      end

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
