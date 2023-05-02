# frozen_string_literal: true

module Audit
  class NamespaceSettingChangesAuditor < BaseChangesAuditor
    EVENT_NAME_PER_COLUMN = {
      code_suggestions: 'code_suggestions_updated',
      experiment_features_enabled: 'experiment_features_enabled_updated',
      third_party_ai_features_enabled: 'third_party_ai_features_enabled_updated'
    }.freeze

    def initialize(current_user, namespace_setting, group)
      @group = group

      super(current_user, namespace_setting)
    end

    def execute
      return if model.blank?

      EVENT_NAME_PER_COLUMN.each do |column, event_name|
        audit_changes(column, entity: @group, model: model, event_type: event_name)
      end
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
