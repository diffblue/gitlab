# frozen_string_literal: true

module EE
  module Projects::IncidentsController
    extend ActiveSupport::Concern

    prepended do
      before_action do
        push_licensed_feature(:escalation_policies, project)

        if project.licensed_feature_available?(:incident_timeline_events)
          push_licensed_feature(:incident_timeline_events)
        end
      end
    end
  end
end
