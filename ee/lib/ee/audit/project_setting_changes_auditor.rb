# frozen_string_literal: true
module EE
  module Audit
    class ProjectSettingChangesAuditor < BaseChangesAuditor
      def initialize(current_user, project_setting, project)
        @project = project

        super(current_user, project_setting)
      end

      def execute
        return if model.blank?

        audit_changes(:squash_option, as: 'squash_option', entity: @project, model: model)
        audit_changes(:allow_merge_on_skipped_pipeline, as: 'allow_merge_on_skipped_pipeline', entity: @project,
                      model: model)
      end

      def attributes_from_auditable_model(column)
        {
          from: model.previous_changes[column].first,
          to: model.previous_changes[column].last,
          target_details: @project.full_path
        }
      end
    end
  end
end
