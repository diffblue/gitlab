# frozen_string_literal: true

module Audit
  class GroupChangesAuditor < BaseChangesAuditor
    COLUMNS = %i[name path repository_size_limit visibility_level
                 request_access_enabled membership_lock lfs_enabled
                 shared_runners_minutes_limit
                 require_two_factor_authentication
                 two_factor_grace_period
                 project_creation_level].freeze

    COLUMN_HUMAN_NAME = {
      visibility_level: 'visibility'
    }.freeze

    def execute
      COLUMNS.each do |column|
        audit_changes(column, as: column_human_name(column), model: model)
      end
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
  end
end
