# frozen_string_literal: true

module Audit
  class NamespaceSettingChangesAuditor < BaseChangesAuditor
    def initialize(current_user, namespace_setting, group)
      @group = group

      super(current_user, namespace_setting)
    end

    def execute
      return if model.blank?
      return unless audit_required? :code_suggestions

      audit_changes(:code_suggestions, entity: @group, model: model, event_type: 'code_suggestions_updated')
    end

    private

    def attributes_from_auditable_model(column)
      {
        from: model.previous_changes[column].first,
        to: model.previous_changes[column].last,
        target_details: @group.full_path
      }
    end
  end
end
