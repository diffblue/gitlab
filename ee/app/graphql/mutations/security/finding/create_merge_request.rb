# frozen_string_literal: true

module Mutations
  module Security
    module Finding
      class CreateMergeRequest < BaseMutation
        graphql_name 'SecurityFindingCreateMergeRequest'

        authorize :admin_vulnerability

        field :merge_request,
          Types::MergeRequestType,
          null: true,
          description: 'Merge Request created after mutation.'

        argument :uuid,
          GraphQL::Types::String,
          required: true,
          description: 'UUID of the security finding to be used to create a merge request.'

        def resolve(uuid:)
          finding = authorized_find!(uuid: uuid)

          prepare_response_for(::Vulnerabilities::SecurityFinding::CreateMergeRequestService.new(
            project: finding.project,
            current_user: current_user,
            params: { security_finding: finding }
          ).execute)
        end

        private

        def find_object(uuid:)
          ::Security::Finding.find_by_uuid(uuid).tap do |finding|
            raise_resource_not_available_error! if finding.blank?

            authorize!(finding.project)
          end
        end

        def prepare_response_for(result)
          return { errors: result.errors } if result.error?

          {
            errors: [],
            merge_request: result.payload[:merge_request]
          }
        end
      end
    end
  end
end
