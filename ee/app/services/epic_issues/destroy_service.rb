# frozen_string_literal: true

module EpicIssues
  class DestroyService < IssuableLinks::DestroyService
    extend ::Gitlab::Utils::Override

    def initialize(link, user)
      @link = link
      @current_user = user
      @source = link.epic
      @target = link.issue
    end

    private

    override :after_destroy
    def after_destroy
      super

      Epics::UpdateDatesService.new([link.epic]).execute

      ::GraphqlTriggers.issuable_epic_updated(@target)
    end

    def track_event
      ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_issue_removed(
        author: current_user,
        namespace: source.group
      )
    end

    def permission_to_remove_relation?
      can?(current_user, :admin_issue_relation, target) && can?(current_user, :read_epic, source)
    end

    def create_notes
      SystemNoteService.epic_issue(source, target, current_user, :removed)
      SystemNoteService.issue_on_epic(target, source, current_user, :removed)
    end
  end
end
