# frozen_string_literal: true

module Audit
  class GroupMergeRequestApprovalSettingChangesAuditor < BaseChangesAuditor
    def initialize(current_user, approval_setting, params)
      @group = approval_setting.group
      @params = params

      super(current_user, approval_setting)
    end

    def execute
      ::GroupMergeRequestApprovalSetting::AUDIT_LOG_ALLOWLIST.each do |column, description|
        audit_change(column, description)
      end
    end

    private

    def audit_change(column, description)
      if model.previously_new_record?
        audit_new_record(column, description)
      else
        audit_changes(column, as: description, entity: @group, model: model, event_type: event_name(column))
      end
    end

    def event_name(column)
      "#{column}_updated"
    end

    def audit_new_record(column, description)
      return unless should_audit_params_column?(column)

      audit_context = {
        name: "group_merge_request_approval_setting_created",
        author: @current_user,
        scope: @group,
        target: @group,
        message: "Changed #{description} from false to true"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    def should_audit_params_column?(column)
      if column == :require_password_to_approve
        @params[column]
      else
        # we are comparing with false here because on UI we show negative statements.
        # where as in tables in store opposite named columns.
        # for example `allow_author_approval` column is shown as Prevent approval by author.
        @params[column] == false
      end
    end

    def attributes_from_auditable_model(column)
      if column == :require_password_to_approve
        {
          from: model.previous_changes[column].first,
          to: model.previous_changes[column].last
        }
      else
        # we are negating here because descriptions shown in the UI and audit events
        # are opposite of column names. For example
        # `allow_author_approval` column has description 'prevent merge request approval from authors'.
        {
          from: !model.previous_changes[column].first,
          to: !model.previous_changes[column].last
        }
      end.merge(target_details: @group.full_path)
    end
  end
end
