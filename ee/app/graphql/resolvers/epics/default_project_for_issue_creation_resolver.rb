# frozen_string_literal: true

module Resolvers
  module Epics
    class DefaultProjectForIssueCreationResolver < BaseResolver
      type Types::ProjectType, null: true

      alias_method :epic, :object

      def resolve(**args)
        return unless current_user

        project = last_issue_creation_event&.project

        return unless project
        return unless Ability.allowed?(current_user, :create_issue, project)
        return unless within_hierarchy?(project)

        project
      end

      private

      def last_issue_creation_event
        EventsFinder.new(
          {
            current_user: current_user,
            source: current_user,
            target_type: "Issue",
            action: "created",
            per_page: 1,
            sort: :desc
          }
        ).execute.last
      end

      def within_hierarchy?(project)
        project.ancestors.include?(epic.group)
      end
    end
  end
end
