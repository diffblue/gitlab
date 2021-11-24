# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class CreateRequirement < BaseRequirement
      include FindsProject

      graphql_name 'CreateRequirement'

      authorize :create_requirement

      def resolve(args)
        project_path = args.delete(:project_path)
        project = authorized_find!(project_path)

        requirement = ::RequirementsManagement::CreateRequirementService.new(
          project: project,
          current_user: context[:current_user],
          params: args
        ).execute

        {
          requirement: requirement.valid? ? requirement : nil,
          errors: errors_on_object(requirement)
        }
      end
    end
  end
end
