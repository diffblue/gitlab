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
        error_message = requirement.errors.messages_for(:requirement_issue).to_sentence

        {
          requirement: requirement.valid? ? requirement : nil,
          errors: error_message.present? ? Array.wrap(error_message) : []
        }
      end
    end
  end
end
