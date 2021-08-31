# frozen_string_literal: true

module Mutations
  module ComplianceManagement
    module Frameworks
      class Update < ::Mutations::BaseMutation
        graphql_name 'UpdateComplianceFramework'

        authorize :manage_compliance_framework

        argument :id,
                 ::Types::GlobalIDType[::ComplianceManagement::Framework],
                 required: true,
                 description: 'Global ID of the compliance framework to update.'

        argument :params, Types::ComplianceManagement::ComplianceFrameworkInputType,
                 required: true,
                 description: 'Parameters to update the compliance framework with.'

        field :compliance_framework,
              Types::ComplianceManagement::ComplianceFrameworkType,
              null: true,
              description: "Compliance framework after mutation."

        def resolve(id:, **args)
          framework = authorized_find!(id: id)
          ::ComplianceManagement::Frameworks::UpdateService.new(framework: framework,
                                                                current_user: current_user,
                                                                params: args[:params].to_h).execute
          { compliance_framework: framework, errors: errors_on_object(framework) }
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::ComplianceManagement::Framework)
        end
      end
    end
  end
end
