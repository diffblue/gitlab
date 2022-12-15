# frozen_string_literal: true

module Audit
  class ExternalStatusCheckChangesAuditor < BaseChangesAuditor
    def initialize(current_user, external_status_check)
      @project = external_status_check.project

      super
    end

    def execute
      audit_changes(:name, as: 'name', entity: @project, model: model,
                           event_type: 'external_status_check_name_updated')

      audit_changes(:external_url, as: 'external url', entity: @project,
                                   model: model,
                                   event_type: 'external_status_check_url_updated')
    end

    def attributes_from_auditable_model(column)
      {
        from: model.previous_changes[column].first,
        to: model.previous_changes[column].last
      }
    end
  end
end
