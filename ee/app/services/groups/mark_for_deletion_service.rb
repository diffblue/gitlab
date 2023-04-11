# frozen_string_literal: true

module Groups
  class MarkForDeletionService < Groups::BaseService
    def execute
      return error(_('You are not authorized to perform this action')) unless can?(current_user, :admin_group, group)
      return error(_('Group has been already marked for deletion')) if group.marked_for_deletion?

      result = create_deletion_schedule
      log_audit_event if result[:status] == :success

      result
    end

    private

    def create_deletion_schedule
      deletion_schedule = group.build_deletion_schedule(deletion_schedule_params)

      if deletion_schedule.save
        success
      else
        errors = deletion_schedule.errors.full_messages.to_sentence

        error(errors)
      end
    end

    def deletion_schedule_params
      { marked_for_deletion_on: Time.current.utc, deleting_user: current_user }
    end

    def log_audit_event
      audit_context = {
        name: 'group_deletion_marked',
        author: current_user,
        scope: group,
        target: group,
        message: 'Group marked for deletion'
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
