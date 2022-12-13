# frozen_string_literal: true

module Resolvers
  module RequirementsManagement
    class RequirementsResolver < BaseResolver
      include LooksAhead
      include CommonRequirementArguments

      type ::Types::RequirementsManagement::RequirementType.connection_type, null: true

      argument :iid, GraphQL::Types::ID,
               required: false,
               description: 'IID of the requirement, e.g., "1".'

      argument :iids, [GraphQL::Types::ID],
               required: false,
               description: 'List of IIDs of requirements, e.g., `[1, 2]`.'

      argument :last_test_report_state, ::Types::RequirementsManagement::RequirementStatusFilterEnum,
               required: false,
               description: 'State of latest requirement test report.'

      def resolve_with_lookahead(**args)
        # The project could have been loaded in batch by `BatchLoader`.
        # At this point we need the `id` of the project to query for issues, so
        # make sure it's loaded and not `nil` before continuing.
        project = object.respond_to?(:sync) ? object.sync : object
        return ::RequirementsManagement::Requirement.none if project.nil?

        args[:project_id] = project.id
        args[:iids] ||= [args[:iid]].compact
        requirements = apply_lookahead(find_requirements(args))

        offset_pagination(requirements)
      end

      private

      def preloads
        {
          last_test_report_manually_created: [:recent_test_reports],
          last_test_report_state: [:recent_test_reports, { recent_test_reports: [:build] }],
          title: :requirement_issue,
          description: :requirement_issue,
          title_html: { requirement_issue: :author },
          description_html: { requirement_issue: :author },
          author: { requirement_issue: :author },
          state: :requirement_issue,
          created_at: :requirement_issue,
          updated_at: :requirement_issue,
          work_item_iid: :requirement_issue
        }
      end

      def find_requirements(args)
        ::RequirementsManagement::RequirementsFinder.new(context[:current_user], args).execute
      end
    end
  end
end
