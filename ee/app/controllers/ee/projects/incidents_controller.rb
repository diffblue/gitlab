# frozen_string_literal: true

module EE
  module Projects::IncidentsController
    extend ActiveSupport::Concern

    prepended do
      before_action do
        push_licensed_feature(:escalation_policies, project)
      end
    end
  end
end
