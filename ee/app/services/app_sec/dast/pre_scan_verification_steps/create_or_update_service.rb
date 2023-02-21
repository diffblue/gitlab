# frozen_string_literal: true

module AppSec
  module Dast
    module PreScanVerificationSteps
      class CreateOrUpdateService < BaseService
        def execute
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          response = verification_step_response
          return response unless response.success?

          verification_step = response.payload[:verification_step]

          verification_step.verification_errors = verification_errors
          verification_step.save

          return ServiceResponse.error(message: error_message(verification_step)) unless verification_step.persisted?

          ServiceResponse.success(payload: { verification_step: verification_step })
        end

        private

        def verification_step_response
          ::AppSec::Dast::PreScanVerificationSteps::FindOrCreateService.new(
            project: project,
            current_user: current_user,
            params: {
              step: step,
              verification: verification
            }
          ).execute
        end

        def verification_errors
          params[:verification_errors]
        end
      end
    end
  end
end
