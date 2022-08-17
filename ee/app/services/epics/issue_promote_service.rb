# frozen_string_literal: true

module Epics
  class IssuePromoteService < ::Issuable::Clone::BaseService
    PromoteError = Class.new(StandardError)

    def execute(issue, epic_group = nil)
      @issue = issue
      @parent_group = epic_group || issue.project.group

      validate_promotion!

      super(@issue, @parent_group)

      track_event
      new_entity
    end

    private

    attr_reader :issue, :parent_group

    def validate_promotion!
      raise PromoteError, _('Cannot promote issue because it does not belong to a group.') if parent_group.nil?
      raise PromoteError, _('Cannot promote issue due to insufficient permissions.') unless can_promote?
      raise PromoteError, _('Issue already promoted to epic.') if issue.promoted?
      raise PromoteError, _('Promotion is not supported.') unless issue.supports_epic?
    end

    def can_promote?
      current_user.can?(:admin_issue, issue) && current_user.can?(:create_epic, parent_group)
    end

    def track_event
      ::Gitlab::Tracking.event('epics', 'promote', property: 'issue_id', value: original_entity.id,
                                                   project: issue.project, user: current_user, namespace: parent_group, weight: issue.weight)

      ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_issue_promoted_to_epic(
        author: current_user,
        namespace: parent_group
      )
    end

    def create_new_entity
      @new_entity = Epics::CreateService.new(group: parent_group, current_user: current_user, params: params).execute
    end

    def update_old_entity
      super

      mark_as_promoted
    end

    def mark_as_promoted
      original_entity.update(promoted_to_epic: new_entity)
    end

    def params
      {
        title: original_entity.title,
        parent: issue_epic,
        confidential: issue.confidential
      }.merge(
        rewritten_old_entity_attributes(include_milestone: false)
      )
    end

    def issue_epic
      original_entity.epic_issue&.epic
    end

    def add_note_from
      SystemNoteService.issue_promoted(new_entity, original_entity, current_user, direction: :from)
    end

    def add_note_to
      SystemNoteService.issue_promoted(original_entity, new_entity, current_user, direction: :to)
    end
  end
end
