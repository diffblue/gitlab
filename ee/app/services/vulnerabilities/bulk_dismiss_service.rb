# frozen_string_literal: true

module Vulnerabilities
  class BulkDismissService
    include Gitlab::Allowable
    MAX_BATCH = 100

    def initialize(current_user, vulnerability_ids, comment, dismissal_reason)
      @user = current_user
      @vulnerability_ids = vulnerability_ids
      @comment = comment
      @dismissal_reason = dismissal_reason
      @project_ids = {}
    end

    def execute
      ensure_authorized_projects!

      vulnerability_ids.each_slice(MAX_BATCH).each do |ids|
        dismiss(Vulnerability.id_in(ids))
      end
      refresh_statistics

      ServiceResponse.success(payload: {
        vulnerabilities: Vulnerability.id_in(vulnerability_ids)
      })
    rescue ActiveRecord::ActiveRecordError
      ServiceResponse.error(message: "Could not dismiss vulnerabilities")
    end

    private

    attr_reader :vulnerability_ids, :user, :comment, :dismissal_reason, :project_ids

    def ensure_authorized_projects!
      raise Gitlab::Access::AccessDeniedError unless authorized_and_ff_enabled?
    end

    def authorized_and_ff_enabled?
      Vulnerability.id_in(vulnerability_ids)
        .projects
        .with_group
        .with_namespace
        .include_project_feature
        .all? do |project|
          can?(user, :admin_vulnerability, project)
        end
    end

    def dismiss(vulnerabilities)
      vulnerability_attrs = vulnerabilities.pluck(:id, :state, :project_id) # rubocop:disable CodeReuse/ActiveRecord
      return if vulnerability_attrs.empty?

      state_transitions = transition_attributes_for(vulnerability_attrs)
      system_notes = system_note_attributes_for(vulnerability_attrs)

      ApplicationRecord.transaction do
        Note.insert_all!(system_notes)
        Vulnerabilities::StateTransition.insert_all!(state_transitions)
        # The `insert_or_update_vulnerability_reads` database trigger does not
        # update the dismissal_reason and we are moving away from using
        # database triggers to keep tables up to date.
        Vulnerabilities::Read
          .by_vulnerabilities(vulnerabilities)
          .update_all(dismissal_reason: dismissal_reason)

        vulnerabilities.update_all(
          state: :dismissed,
          dismissed_by_id: user.id,
          dismissed_at: now,
          updated_at: now
        )
      end
    end

    def transition_attributes_for(attrs)
      attrs.map do |id, state, _|
        {
          vulnerability_id: id,
          from_state: state,
          to_state: :dismissed,
          comment: comment,
          dismissal_reason: dismissal_reason,
          author_id: user.id,
          created_at: now,
          updated_at: now
        }
      end
    end

    def system_note_attributes_for(attrs)
      attrs.map do |id, _, project_id|
        project_ids[project_id] = true
        {
          noteable_type: "Vulnerability",
          noteable_id: id,
          project_id: project_id,
          system: true,
          note: ::SystemNotes::VulnerabilitiesService.formatted_note(
            'changed',
            :dismissed,
            dismissal_reason.to_s.titleize,
            comment
          ),
          author_id: user.id,
          created_at: now,
          updated_at: now
        }
      end
    end

    def refresh_statistics
      return if project_ids.empty?

      Vulnerabilities::Statistics::AdjustmentWorker.perform_async(project_ids.keys)
    end

    # We use this for setting the created_at and updated_at timestamps
    # for the various records created by this service.
    # The time is memoized on the first call to this method so all of the
    # created records will have the same timestamps.
    def now
      @now ||= Time.current.utc
    end
  end
end
