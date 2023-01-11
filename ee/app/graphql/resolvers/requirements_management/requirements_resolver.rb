# frozen_string_literal: true

module Resolvers
  module RequirementsManagement
    class RequirementsResolver < BaseResolver
      include LooksAhead
      include CommonRequirementArguments

      type ::Types::RequirementsManagement::RequirementType.connection_type, null: true

      argument :iid, GraphQL::Types::ID,
               required: false,
               deprecated: { reason: 'Use work_item_iid instead', milestone: '15.8' },
               description: 'IID of the requirement, for example, "1".'

      argument :iids, [GraphQL::Types::ID],
               required: false,
               deprecated: { reason: 'Use work_item_iids instead', milestone: '15.8' },
               description: 'List of IIDs of requirements, for example, `[1, 2]`.'

      argument :work_item_iid, GraphQL::Types::ID, # rubocop:disable Graphql/IDType
               required: false,
               description: 'IID of the requirement work item, for example, "1".'

      argument :work_item_iids, [GraphQL::Types::ID],
               required: false,
               description: 'List of IIDs of requirement work items, for example, `[1, 2]`.'

      argument :last_test_report_state, ::Types::RequirementsManagement::RequirementStatusFilterEnum,
               required: false,
               description: 'State of latest requirement test report.'

      def resolve_with_lookahead(**args)
        # The project could have been loaded in batch by `BatchLoader`.
        # At this point we need the `id` of the project to query for issues, so
        # make sure it's loaded and not `nil` before continuing.
        project = object.respond_to?(:sync) ? object.sync : object
        return ::RequirementsManagement::Requirement.none if project.nil?

        args = sanitize_arguments(args, project)

        requirements = apply_lookahead(find_requirements(args))

        offset_pagination(requirements)
      end

      private

      def sanitize_arguments(args, project)
        args.tap do |values|
          values[:project_id] = project.id
          values[:issue_types] = [:requirement]
          values[:iids] ||= [args[:iid]].compact
          values[:work_item_iids] ||= [args[:work_item_iid]].compact

          # The'archived' state does not exist for work items
          # we need to translate it to 'closed' here to proper filter items
          values[:state] = 'closed' if values[:state].to_s == 'archived'

          # Last test report state is a widget on work items
          # We need to parse the parameter here to filter work items correctly
          if values[:last_test_report_state].present?
            values[:status_widget] = { status: args.delete(:last_test_report_state) }
          end
        end
      end

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

      # rubocop: disable CodeReuse/ActiveRecord
      def find_requirements(args)
        legacy_iids = args.delete(:iids)

        work_items_ids = ::WorkItems::WorkItemsFinder
                           .new(current_user, args.merge(iids: args[:work_item_iids]))
                           .execute.select(:id)

        requirements =
          ::RequirementsManagement::Requirement.where(issue_id: work_items_ids.reorder(nil))

        # keeps old requirement iids filter backwards compatible
        requirements = requirements.where(iid: legacy_iids) if legacy_iids.present?

        # Preserve the same ordering from the ids returned from WorkItemsFinder
        # Prevents joining issues table again to have the correct sort
        requirements.order(Arel.sql("array_position(ARRAY(#{work_items_ids.to_sql})::bigint[], requirements.issue_id)"))
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
