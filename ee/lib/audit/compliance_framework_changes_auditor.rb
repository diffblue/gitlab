# frozen_string_literal: true

module Audit
  class ComplianceFrameworkChangesAuditor < BaseChangesAuditor
    def initialize(current_user, compliance_framework_setting, project)
      @project = project

      super(current_user, compliance_framework_setting)
    end

    def execute
      return if model.blank?

      if model.destroyed?
        audit_context = {
          author: @current_user,
          scope: @project,
          target: @project,
          message: 'Unassigned project compliance framework',
          name: 'compliance_framework_deleted'
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      else
        audit_changes(:framework_id, as: 'compliance framework', model: model, entity: @project,
                                     event_type: 'compliance_framework_id_updated')
      end
    end

    def framework_changes
      model.previous_changes["framework_id"]
    end

    def old_framework_name
      ComplianceManagement::Framework.find_by_id(framework_changes.first)&.name || "None"
    end

    def new_framework_name
      ComplianceManagement::Framework.find_by_id(framework_changes.last)&.name || "None"
    end

    def attributes_from_auditable_model(column)
      {
        from: old_framework_name,
        to: new_framework_name,
        target_details: @project.full_path
      }
    end
  end
end
