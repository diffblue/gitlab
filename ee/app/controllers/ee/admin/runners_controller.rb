# frozen_string_literal: true

module EE
  module Admin
    module RunnersController
      extend ActiveSupport::Concern

      prepended do
        before_action(only: [:index]) { push_licensed_feature(:runner_performance_insights) }
        before_action(only: [:index, :show]) { push_licensed_feature(:runner_upgrade_management) }
        before_action(only: [:show, :edit]) { push_licensed_feature(:runner_maintenance_note) }
      end
    end
  end
end
