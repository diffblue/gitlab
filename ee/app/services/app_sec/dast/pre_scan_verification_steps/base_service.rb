# frozen_string_literal: true

module AppSec
  module Dast
    module PreScanVerificationSteps
      class BaseService < BaseProjectService
        private

        def allowed?
          can?(@current_user, :create_on_demand_dast_scan, @project) && verification.project == @project
        end

        def verification
          @verification ||= params[:verification]
        end

        def step
          @step ||= params[:step]
        end

        def error_message(pre_step)
          format_error_message(pre_step.errors.full_messages.join(', '))
        end

        def format_error_message(errors)
          format(_('Error creating or updating PreScanVerificationStep: %{errors}'), errors: errors)
        end
      end
    end
  end
end
