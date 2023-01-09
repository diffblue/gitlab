# frozen_string_literal: true

module EE
  module SystemNoteHelper
    extend ::Gitlab::Utils::Override

    EE_ICON_NAMES_BY_ACTION = {
      'relate' => 'link',
      'unrelate' => 'unlink',
      'epic_issue_added' => 'issues',
      'epic_issue_removed' => 'issues',
      'epic_issue_moved' => 'issues',
      'issue_added_to_epic' => 'epic',
      'issue_removed_from_epic' => 'epic',
      'issue_changed_epic' => 'epic',
      'epic_date_changed' => 'calendar',
      'iteration' => 'iteration',
      'weight' => 'weight',
      'relate_epic' => 'epic',
      'unrelate_epic' => 'epic',
      'vulnerability_detected' => 'search-dot',
      'vulnerability_confirmed' => 'shield',
      'vulnerability_dismissed' => 'cancel',
      'vulnerability_resolved' => 'status_closed',
      'published' => 'bullhorn',
      'paging_started' => 'mobile',
      'progress' => 'progress'
    }.freeze

    override :system_note_icon_name
    def system_note_icon_name(note)
      EE_ICON_NAMES_BY_ACTION[note.system_note_metadata&.action] || super
    end
  end
end
