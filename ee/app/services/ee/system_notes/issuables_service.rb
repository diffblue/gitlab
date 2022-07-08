# frozen_string_literal: true
module EE
  module SystemNotes
    module IssuablesService
      extend ::Gitlab::Utils::Override
      # Called when the health_status of an Issue is changed
      #
      # Example Note text:
      #
      #   "removed the health status"
      #
      #   "changed health status to at risk"
      #
      # Returns the created Note object
      def change_health_status_note
        health_status = noteable.health_status&.humanize(capitalize: false)
        body = health_status ? "changed health status to **#{health_status}**" : 'removed the health status'

        if noteable.is_a?(Issue)
          issue_activity_counter.track_issue_health_status_changed_action(author: author, project: project)
        end

        create_note(NoteSummary.new(noteable, project, author, body, action: 'health_status'))
      end

      # Called when the an issue is published to a project's
      # status page application
      #
      # Example Note text:
      #
      #   "published this issue to the status page"
      #
      # Returns the created Note object
      def publish_issue_to_status_page
        body = 'published this issue to the status page'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'published'))
      end

      override :track_cross_reference_action
      def track_cross_reference_action
        super

        counter = ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter

        counter.track_epic_cross_referenced(author: author) if noteable.is_a?(Epic)
      end
    end
  end
end
