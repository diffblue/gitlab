# frozen_string_literal: true

module Audit
  class GroupChangesAuditor < BaseChangesAuditor
    COLUMN_HUMAN_NAME = {
      visibility_level: 'visibility'
    }.freeze

    EVENT_NAME_PER_COLUMN = {
      name: 'group_name_updated',
      path: 'group_path_updated',
      repository_size_limit: 'group_repository_size_limit_updated',
      visibility_level: 'group_visibility_level_updated',
      request_access_enabled: 'group_request_access_enabled_updated',
      membership_lock: 'group_membership_lock_updated',
      lfs_enabled: 'group_lfs_enabled_updated',
      shared_runners_minutes_limit: 'group_shared_runners_minutes_limit_updated',
      require_two_factor_authentication: 'group_require_two_factor_authentication_updated',
      two_factor_grace_period: 'group_two_factor_grace_period_updated',
      project_creation_level: 'group_project_creation_level_updated'
    }.freeze

    def execute
      EVENT_NAME_PER_COLUMN.each do |column, event_name|
        audit_changes(column, as: column_human_name(column), model: model,
                              event_type: event_name)
      end

      audit_namespace_setting_changes
    end

    def attributes_from_auditable_model(column)
      old = model.previous_changes[column].first
      new = model.previous_changes[column].last

      case column
      when :visibility_level
        {
          from: ::Gitlab::VisibilityLevel.level_name(old),
          to: ::Gitlab::VisibilityLevel.level_name(new)
        }
      when :project_creation_level
        {
          from: ::Gitlab::Access.project_creation_level_name(old),
          to: ::Gitlab::Access.project_creation_level_name(new)
        }
      else
        {
          from: old,
          to: new
        }
      end
    end

    private

    def column_human_name(column)
      COLUMN_HUMAN_NAME.fetch(column, column.to_s)
    end

    def audit_namespace_setting_changes
      Audit::NamespaceSettingChangesAuditor.new(@current_user, model.namespace_settings, model).execute
    end
  end
end
