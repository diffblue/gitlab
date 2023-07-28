# frozen_string_literal: true

module Audit
  class ApplicationSettingChangesAuditor < BaseChangesAuditor
    def execute
      return if model.blank?

      changed_columns = model.previous_changes.except!(:updated_at)

      changed_columns.each_key do |column|
        next if auditable_attribute?(column)

        audit_changes(column, as: column.to_s, model: model,
          entity: Gitlab::Audit::InstanceScope.new,
          event_type: "application_setting_updated")
      end
    end

    private

    def auditable_attribute?(column)
      !!(column =~ /_html\Z/) || !!(column =~ /^encrypted_/)
    end

    def attributes_from_auditable_model(column)
      {
        from: model.previous_changes[column].first,
        to: model.previous_changes[column].last,
        target_details: column.humanize
      }
    end
  end
end
