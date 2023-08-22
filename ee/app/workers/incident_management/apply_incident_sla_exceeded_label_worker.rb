# frozen_string_literal: true

module IncidentManagement
  class ApplyIncidentSlaExceededLabelWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    feature_category :incident_management

    def perform(incident_id)
      @incident = Issue.find_by_id(incident_id)
      return unless incident&.sla_available?

      @project = incident&.project
      return unless project

      @label = incident_exceeded_sla_label
      if incident.label_ids.include?(label.id)
        set_label_applied_boolean
        return
      end

      incident.labels << label
      set_label_applied_boolean
      add_resource_event
    end

    private

    attr_reader :incident, :project, :label

    def set_label_applied_boolean
      incident.issuable_sla.update(label_applied: true)
    end

    def add_resource_event
      ResourceEvents::ChangeLabelsService
        .new(incident, Users::Internal.alert_bot)
        .execute(added_labels: [label])
    end

    def incident_exceeded_sla_label
      ::IncidentManagement::CreateIncidentSlaExceededLabelService
        .new(project)
        .execute
        .payload[:label]
    end
  end
end
