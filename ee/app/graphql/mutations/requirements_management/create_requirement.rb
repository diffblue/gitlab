# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class CreateRequirement < BaseRequirement
      graphql_name 'CreateRequirement'

      include FindsProject

      authorize :create_requirement

      def resolve(args)
        project_path = args.delete(:project_path)
        project = authorized_find!(project_path)

        requirement = ::RequirementsManagement::CreateRequirementService.new(
          project: project,
          current_user: context[:current_user],
          params: args
        ).execute

        if requirement.errors.empty?
          { requirement: requirement, errors: [] }
        else
          requirement.errors.delete(:requirement_issue)

          { requirement: nil, errors: errors_on_object(requirement) }
        end
      end
    end
  end
end
