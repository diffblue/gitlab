# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class RevertToDetected < BaseMutation
      graphql_name 'VulnerabilityRevertToDetected'

      authorize :admin_vulnerability

      field :vulnerability, Types::VulnerabilityType,
            null: true,
            description: 'Vulnerability after revert.'

      argument :id,
               ::Types::GlobalIDType[::Vulnerability],
               required: true,
               description: 'ID of the vulnerability to be reverted.'

      def resolve(id:)
        vulnerability = authorized_find!(id: id)
        result = ::Vulnerabilities::RevertToDetectedService.new(current_user, vulnerability).execute

        {
          vulnerability: result,
          errors: result.errors.full_messages || []
        }
      end

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Vulnerability)
      end
    end
  end
end
