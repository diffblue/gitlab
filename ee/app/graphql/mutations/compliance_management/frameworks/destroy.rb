# frozen_string_literal: true

module Mutations
  module ComplianceManagement
    module Frameworks
      class Destroy < ::Mutations::BaseMutation
        graphql_name 'DestroyComplianceFramework'

        authorize :manage_compliance_framework

        argument :id,
                 ::Types::GlobalIDType[::ComplianceManagement::Framework],
                 required: true,
                 description: 'Global ID of the compliance framework to destroy.'

        def resolve(id:)
          framework = authorized_find!(id: id)
          result = ::ComplianceManagement::Frameworks::DestroyService.new(framework: framework, current_user: current_user).execute

          { errors: result.success? ? [] : Array.wrap(result.message) }
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::ComplianceManagement::Framework)
        end
      end
    end
  end
end
