# frozen_string_literal: true

module SystemNotes
  class EpicsService < ::SystemNotes::BaseService
    def epic_issue(issue, type)
      return unless validate_epic_issue_action_type(type)

      action = type == :added ? 'epic_issue_added' : 'epic_issue_removed'

      body = "#{type} issue #{issue.to_reference(noteable.group)}"

      create_note(NoteSummary.new(noteable, nil, author, body, action: action))
    end

    def epic_issue_moved(issue, to_epic)
      epic_issue_moved_act(noteable, issue, to_epic, author, verb: 'added', direction: 'from')
      epic_issue_moved_act(to_epic, issue, noteable, author, verb: 'moved', direction: 'to')
    end

    def issue_promoted(noteable_ref, direction:)
      unless [:to, :from].include?(direction)
        raise ArgumentError, "Invalid direction `#{direction}`"
      end

      project = noteable.project

      cross_reference = noteable_ref.to_reference(project || noteable.group)
      body = "promoted #{direction} #{noteable_ref.class.to_s.downcase} #{cross_reference}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'moved'))
    end

    def issue_on_epic(issue, type)
      return unless validate_epic_issue_action_type(type)

      if type == :added
        direction = 'to'
        action = 'issue_added_to_epic'
      else
        direction = 'from'
        action = 'issue_removed_from_epic'
      end

      body = "#{type} #{direction} epic #{noteable.to_reference(issue.project)}"

      create_note(NoteSummary.new(issue, issue.project, author, body, action: action))
    end

    def issue_epic_change(issue)
      body = "changed epic to #{noteable.to_reference(issue.project)}"
      action = 'issue_changed_epic'

      create_note(NoteSummary.new(issue, issue.project, author, body, action: action))
    end

    # Called when the start or end date of an Issuable is changed
    #
    # date_type  - 'start date' or 'finish date'
    # date       - New date
    #
    # Example Note text:
    #
    #   "changed start date to FIXME"
    #
    # Returns the created Note object
    def change_epic_date_note(date_type, date)
      body = if date
               "changed #{date_type} to #{date.strftime('%b %-d, %Y')}"
             else
               "removed the #{date_type}"
             end

      create_note(NoteSummary.new(noteable, nil, author, body, action: 'epic_date_changed'))
    end

    def change_epics_relation(child_epic, type)
      note_body = if type == 'relate_epic'
                    "added epic %{target_epic_ref} as %{direction} epic"
                  else
                    "removed %{direction} epic %{target_epic_ref}"
                  end

      note_body_params = { direction: 'child', target_epic_ref: child_epic.to_reference(noteable.group) }
      create_note(NoteSummary.new(noteable, nil, author, note_body % note_body_params, action: type))

      note_body_params = { direction: 'parent', target_epic_ref: noteable.to_reference(child_epic.group) }
      create_note(NoteSummary.new(child_epic, nil, author, note_body % note_body_params, action: type))
    end

    def move_child_epic_to_new_parent(child_epic, new_parent_epic)
      note_body = "moved child epic %{target_epic_ref} to epic %{new_parent_epic_ref}"
      note_body_params = {
        target_epic_ref: child_epic.to_reference(noteable.group),
        new_parent_epic_ref: new_parent_epic.to_reference(child_epic.group)
      }

      create_note(NoteSummary.new(noteable, nil, author, note_body % note_body_params, action: 'moved'))
    end

    private

    def epic_issue_moved_act(subject_epic, issue, object_epic, user, verb:, direction:)
      action = 'epic_issue_moved'

      body = "#{verb} issue #{issue.to_reference(subject_epic.group)} #{direction}" \
              " epic #{subject_epic.to_reference(object_epic.group)}"

      create_note(NoteSummary.new(object_epic, nil, user, body, action: action))
    end

    def validate_epic_issue_action_type(type)
      [:added, :removed].include?(type)
    end
  end
end
