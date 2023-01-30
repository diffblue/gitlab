# frozen_string_literal: true

module EE
  module Issues
    module ExportCsvService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      attr_accessor :user, :cached_redacted_epics

      override :initialize
      def initialize(relation, resource_parent, user = nil)
        super

        @cached_redacted_epics = {}
        @user = user
      end

      override :associations_to_preload
      def associations_to_preload
        return super unless epics_available?

        super.concat([:epic, :epic_issue])
      end

      override :header_to_value_hash
      def header_to_value_hash
        return super unless epics_available?

        super.merge({
          'Epic ID' => epic_issue_safe(:id),
          'Epic Title' => epic_issue_safe(:title)
        })
      end

      def epic_issue_safe(attribute)
        lambda do |issue|
          epic = redacted_epic_for(issue)

          next if epic.nil?

          epic[attribute]
        end
      end

      def redacted_epic_for(issue)
        epic = issue.epic

        return unless epic
        return cached_redacted_epics[epic.id] if cached_redacted_epics.has_key?(epic.id)

        epic.title = nil unless Ability.allowed?(user, :read_epic, epic)

        cached_redacted_epics[epic.id] = epic

        epic
      end

      def epics_available?
        strong_memoize(:epics_available) do
          resource_parent.group&.feature_available?(:epics)
        end
      end
    end
  end
end
