# frozen_string_literal: true

# This is part of the migration from Requirement (the first class object)
# to Issue/Work Item (of type Requirement).
# This file can be removed on cleanup phase, for more information check:
# https://gitlab.com/gitlab-org/gitlab/-/issues/323779#hourglass-stage-v-dropping-of-requirements-table-cleanup-329432

module RequirementsManagement
  module SyncWithRequirementIssue
    def sync_issue_for(requirement)
      # We can't wrap the change in a Transaction (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64929#note_647123684)
      # so we'll check if both are valid before saving
      if requirement.valid? && (requirement.requirement_issue || requirement.new_record?)
        synced_issue = save_requirement_issue(requirement)

        return synced_issue if synced_issue.valid?

        requirement.requirement_issue_sync_error!

        ::Gitlab::AppLogger.info(message: "Requirement-Issue Sync: Associated issue could not be saved", project_id: project.id, user_id: current_user.id, params: params)

        nil
      end
    end

    def save_requirement_issue(requirement)
      sync_params = RequirementsManagement::Requirement.sync_params
      changed_attrs = requirement.changed.map(&:to_sym) & sync_params

      return unless changed_attrs.any?

      sync_attrs = requirement.attributes.with_indifferent_access.slice(*changed_attrs)

      perform_sync(requirement, sync_attrs)
    end

    # Overriden on subclasses
    # To sync on create or on update
    def perform_sync(requirement, attributes)
      raise NotImplementedError, "#{self.class} does not implement #{__method__}"
    end
  end
end
