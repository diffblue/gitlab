# frozen_string_literal: true

# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.
module EE
  module SystemNoteService
    extend ActiveSupport::Concern
    include ActionView::RecordIdentifier

    prepended do
      # ::SystemNoteService wants the methods to be available as both class and
      # instance methods. This removes the need for having to both `include` and
      # `extend` this module everywhere it is used.
      extend_mod_with('SystemNoteService') # rubocop: disable Cop/InjectEnterpriseEditionModule
    end

    def epic_issue(epic, issue, user, type)
      epics_service(epic, user).epic_issue(issue, type)
    end

    def epic_issue_moved(from_epic, issue, to_epic, user)
      epics_service(from_epic, user).epic_issue_moved(issue, to_epic)
    end

    def issue_promoted(noteable, noteable_ref, author, direction:)
      epics_service(noteable, author).issue_promoted(noteable_ref, direction: direction)
    end

    def issue_on_epic(issue, epic, user, type)
      epics_service(epic, user).issue_on_epic(issue, type)
    end

    def issue_epic_change(issue, epic, user)
      epics_service(epic, user).issue_epic_change(issue)
    end

    # Called when the health_stauts of an Issue is changed
    #
    # noteable   - Noteable object
    # project    - Project owning noteable
    # author     - User performing the change
    #
    # Example Note text:
    #
    #   "removed the health status"
    #   "changed health status to 'at risk'"
    #
    # Returns the created Note object
    def change_health_status_note(noteable, project, author, previous_status)
      issuables_service(noteable, project, author).change_health_status_note(previous_status)
    end

    # Called when the start or end date of an Issuable is changed
    #
    # noteable   - Noteable object
    # author     - User performing the change
    # date_type  - 'start date' or 'finish date'
    # date       - New date
    #
    # Example Note text:
    #
    #   "changed start date to FIXME"
    #
    # Returns the created Note object
    def change_epic_date_note(noteable, author, date_type, date)
      epics_service(noteable, author).change_epic_date_note(date_type, date)
    end

    def change_epics_relation(epic, child_epic, user, type)
      epics_service(epic, user).change_epics_relation(child_epic, type)
    end

    def move_child_epic_to_new_parent(previous_parent_epic:, child_epic:, new_parent_epic:, user:)
      epics_service(previous_parent_epic, user).move_child_epic_to_new_parent(child_epic, new_parent_epic)
    end

    # Called when 'merge train' is executed
    def merge_train(noteable, project, author, merge_train)
      merge_trains_service(noteable, project, author).enqueue(merge_train)
    end

    # Called when 'merge train' is canceled
    def cancel_merge_train(noteable, project, author)
      merge_trains_service(noteable, project, author).cancel
    end

    # Called when 'merge train' is aborted
    def abort_merge_train(noteable, project, author, reason)
      merge_trains_service(noteable, project, author).abort(reason)
    end

    # Called when 'add to merge train when pipeline succeeds' is executed
    def add_to_merge_train_when_pipeline_succeeds(noteable, project, author, sha)
      merge_trains_service(noteable, project, author).add_when_pipeline_succeeds(sha)
    end

    # Called when 'add to merge train when pipeline succeeds' is canceled
    def cancel_add_to_merge_train_when_pipeline_succeeds(noteable, project, author)
      merge_trains_service(noteable, project, author).cancel_add_when_pipeline_succeeds
    end

    # Called when 'add to merge train when pipeline succeeds' is aborted
    def abort_add_to_merge_train_when_pipeline_succeeds(noteable, project, author, reason)
      merge_trains_service(noteable, project, author).abort_add_when_pipeline_succeeds(reason)
    end

    # Called when state is changed for 'vulnerability'
    def change_vulnerability_state(noteable, author, body = nil)
      vulnerabilities_service(noteable, noteable.project, author).change_vulnerability_state(body)
    end

    # Called when quick action to publish an issue to status page is called
    def publish_issue_to_status_page(noteable, project, author)
      issuables_service(noteable, project, author).publish_issue_to_status_page
    end

    def notify_via_escalation(noteable, project, recipients, escalation_policy, type)
      escalations_service(noteable, project).notify_via_escalation(recipients, escalation_policy: escalation_policy, type: type)
    end

    def start_escalation(noteable, escalation_policy, author)
      escalations_service(noteable, noteable.project).start_escalation(escalation_policy, author)
    end

    def issuable_resource_link_added(incident, project, author, link_type)
      issuable_resource_links_service(incident, project, author).issuable_resource_link_added(link_type)
    end

    def issuable_resource_link_removed(incident, project, author, link_type)
      issuable_resource_links_service(incident, project, author).issuable_resource_link_removed(link_type)
    end

    # Called when Issuable got linked using `blocks` link
    #
    # noteable      - Noteable object
    # noteable_ref  - Noteable object
    # author        - User performing the linking action
    #
    # Returns the created Note object
    def block_issuable(noteable, noteable_ref, user)
      issuables_service(noteable, noteable.project, user).block_issuable(noteable_ref)
    end

    # Called when Issuable got blocked
    #
    # noteable      - Noteable object
    # noteable_ref  - Noteable object
    # author        - User performing the linking action
    #
    # Returns the created Note object
    def blocked_by_issuable(noteable, noteable_ref, user)
      issuables_service(noteable, noteable.project, user).blocked_by_issuable(noteable_ref)
    end

    def change_progress_note(noteable, user)
      issuables_service(noteable, noteable.project, user).change_progress_note
    end

    private

    def issuables_service(noteable, project, author)
      ::SystemNotes::IssuablesService.new(noteable: noteable, project: project, author: author)
    end

    def epics_service(noteable, author)
      ::SystemNotes::EpicsService.new(noteable: noteable, author: author)
    end

    def merge_trains_service(noteable, project, author)
      ::SystemNotes::MergeTrainService.new(noteable: noteable, project: project, author: author)
    end

    def vulnerabilities_service(noteable, project, author)
      ::SystemNotes::VulnerabilitiesService.new(noteable: noteable, project: project, author: author)
    end

    def escalations_service(noteable, project)
      ::SystemNotes::EscalationsService.new(noteable: noteable, project: project)
    end

    def issuable_resource_links_service(noteable, project, author)
      ::SystemNotes::IssuableResourceLinksService.new(noteable: noteable, project: project, author: author)
    end
  end
end
