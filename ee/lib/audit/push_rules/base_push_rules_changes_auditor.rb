# frozen_string_literal: true

module Audit
  module PushRules
    class BasePushRulesChangesAuditor < BaseChangesAuditor
      STRING_KEYS = [
        :branch_name_regex, :commit_message_regex, :commit_message_negative_regex, :author_email_regex,
        :file_name_regex, :max_file_size
      ].freeze

      private

      def attributes_from_auditable_model(column)
        before = model.previous_changes[column].first
        after = model.previous_changes[column].last

        {
          from: before || null_value(column),
          to: after || null_value(column),
          target_details: target_details
        }
      end

      def audit_required?(column)
        should_audit?(column)
      end

      def null_value(column)
        STRING_KEYS.include?(column) ? nil : false
      end
    end
  end
end
