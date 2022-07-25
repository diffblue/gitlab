# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class CreateRequirement < BaseRequirement
      graphql_name 'CreateRequirement'

      include FindsProject
      include Mutations::SpamProtection

      authorize :create_requirement

      def resolve(args)
        project_path = args.delete(:project_path)
        project = authorized_find!(project_path)
        args[:issue_type] = :requirement
        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        issue = ::Issues::CreateService.new(
          project: project,
          current_user: current_user,
          params: args,
          spam_params: spam_params
        ).execute

        check_spam_action_response!(issue) if issue

        if issue.errors.empty?
          { requirement: issue.requirement, errors: [] }
        else
          { requirement: nil, errors: errors_on_object(issue) }
        end
      end
    end
  end
end
