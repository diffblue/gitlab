# frozen_string_literal: true

module EE
  module Issues
    module ExportCsvService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

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
          epic = issue.epic

          next if epic.nil?
          next unless issue.epic_issue.epic_and_issue_at_same_group_hierarchy? # TODO This check can be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/339514

          epic[attribute]
        end
      end

      def epics_available?
        strong_memoize(:epics_available) do
          project.group&.feature_available?(:epics)
        end
      end
    end
  end
end
