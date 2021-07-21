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
               required: true,
               description: 'The IID of the requirement to update.'

      argument :last_test_report_state, Types::RequirementsManagement::TestReportStateEnum,
               required: false,
               description: 'Creates a test report for the requirement with the given state.'

      def ready?(**args)
        update_args = [:title, :state, :last_test_report_state, :description]
        if args.values_at(*update_args).compact.blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
            "At least one of #{update_args.join(', ')} is required"
        end

        super
      end

      def resolve(args)
        project_path = args.delete(:project_path)
        requirement_iid = args.delete(:iid)
        requirement = authorized_find!(project_path: project_path, iid: requirement_iid)

        requirement = ::RequirementsManagement::UpdateRequirementService.new(
          requirement.project,
          context[:current_user],
          args
        ).execute(requirement)

        {
          requirement: requirement.reset,
          errors: errors_on_object(requirement)
        }
      end

      private

      def find_object(project_path:, iid:)
        project = resolve_project(full_path: project_path)

        resolver = Resolvers::RequirementsManagement::RequirementsResolver
          .single.new(object: project, context: context, field: nil)

        resolver.resolve(iid: iid)
      end
    end
  end
end
