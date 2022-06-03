# frozen_string_literal: true

module EE
  module Admin
    module RunnersController
      extend ActiveSupport::Concern

      prepended do
        before_action(only: [:show, :edit]) { push_licensed_feature(:runner_maintenance_note) }
      end
    end
  end
end
