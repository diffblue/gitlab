# frozen_string_literal: true

module Audit
  class GroupPushRulesChangesAuditor < BaseChangesAuditor
    STRING_KEYS = [
      :branch_name_regex, :commit_message_regex, :commit_message_negative_regex, :author_email_regex,
      :file_name_regex, :max_file_size
    ].freeze

    def execute
      return if model.blank? || model.group.nil?

      ::PushRule::AUDIT_LOG_ALLOWLIST.each do |attr, desc|
        audit_changes(attr, as: desc, entity: model.group, model: model)
      end
    end

    private

    def audit_required?(column)
      should_audit?(column)
    end

    def attributes_from_auditable_model(column)
      before = model.previous_changes[column].first
      after = model.previous_changes[column].last
      {
        from: before || null_value(column),
        to: after || null_value(column),
        target_details: model.group.full_path
      }
    end

    def null_value(column)
      STRING_KEYS.include?(column) ? nil : false
    end
  end
end
