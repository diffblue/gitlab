# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class UpdateRequirement < BaseRequirement
      graphql_name 'UpdateRequirement'

      authorize :update_requirement

      argument :state, Types::RequirementsManagement::RequirementStateEnum,
               required: false,
               description: 'State of the requirement.'

      argument :iid, GraphQL::Types::String,
               required: false,
               deprecated: { reason: 'Use work_item_iid instead', milestone: '15.8' },
               description: 'IID of the requirement to update.'

      argument :work_item_iid, GraphQL::Types::String,
               required: false,
               description: 'IID of the requirement work item to update.'

      argument :last_test_report_state, Types::RequirementsManagement::TestReportStateEnum,
               required: false,
               description: 'Creates a test report for the requirement with the given state.'

      def ready?(**args)
        errors = []
        if args.slice(*mutually_exclusive_iid_args).size != 1
          iid_args = mutually_exclusive_iid_args.map { |x| x.to_s.camelize(:lower) }.join(' or ')
          errors << "One and only one of #{iid_args} is required"
        end

        update_args = [:title, :state, :last_test_report_state, :description]
        errors << "At least one of #{update_args.join(', ')} is required" if args.values_at(*update_args).compact.blank?

        raise Gitlab::Graphql::Errors::ArgumentError, errors.join("; ") if errors.any?

        super
      end

      def resolve(args)
        project_path = args.delete(:project_path)
        requirement_iid = args.delete(:iid)
        work_item_iid = args.delete(:work_item_iid)
        requirement = authorized_find!(project_path: project_path, iid: requirement_iid, work_item_iid: work_item_iid)
        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        # Keeps the mutation state argument backwards compatible
        # because this now updates an issue.
        args[:state] = 'closed' if args[:state].to_s == 'archived'

        issue = ::Issues::UpdateService.new(
          container: requirement.project,
          current_user: context[:current_user],
          params: args,
          spam_params: spam_params
        ).execute(requirement.requirement_issue)

        {
          requirement: issue.reset.requirement,
          errors: errors_on_object(issue)
        }
      end

      private

      def find_object(project_path:, iid:, work_item_iid:)
        project = resolve_project(full_path: project_path)

        resolver = Resolvers::RequirementsManagement::RequirementsResolver
          .single.new(object: project, context: context, field: nil)

        resolver.resolve(iid: iid, work_item_iid: work_item_iid)
      end

      def mutually_exclusive_iid_args
        [:iid, :work_item_iid]
      end
    end
  end
end
