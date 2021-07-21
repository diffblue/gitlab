# frozen_string_literal: true

module IncidentManagement
  class ApplyIncidentSlaExceededLabelWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    feature_category :incident_management
    tags :exclude_from_kubernetes

    def perform(incident_id)
      @incident = Issue.find_by_id(incident_id)
      return unless incident&.sla_available?

      @project = incident&.project
      return unless project

      @label = incident_exceeded_sla_label
      return if incident.label_ids.include?(label.id)

      incident.labels << label
      add_resource_event
    end

    private

    attr_reader :incident, :project, :label

    def add_resource_event
      ResourceEvents::ChangeLabelsService
        .new(incident, User.alert_bot)
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
