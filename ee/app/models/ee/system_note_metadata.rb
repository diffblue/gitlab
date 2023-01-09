# frozen_string_literal: true

module EE
  module SystemNoteMetadata
    extend ::Gitlab::Utils::Override

    EE_ICON_TYPES = %w[
      weight published
      epic_issue_added issue_added_to_epic epic_issue_removed issue_removed_from_epic
      epic_issue_moved issue_changed_epic epic_date_changed relate_epic unrelate_epic
      vulnerability_confirmed vulnerability_dismissed vulnerability_resolved vulnerability_detected
      iteration paging_started progress
    ].freeze

    EE_TYPES_WITH_CROSS_REFERENCES = %w[
      epic_issue_added issue_added_to_epic epic_issue_removed issue_removed_from_epic
      epic_issue_moved issue_changed_epic relate_epic unrelate_epic
      iteration
    ].freeze

    override :icon_types
    def icon_types
      @icon_types ||= (super + EE_ICON_TYPES).freeze
    end

    override :cross_reference_types
    def cross_reference_types
      @cross_reference_types ||= (super + EE_TYPES_WITH_CROSS_REFERENCES).freeze
    end
  end
end
