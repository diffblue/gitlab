# frozen_string_literal: true

module AppSec
  module Dast
    module PreScanVerificationSteps
      class FindOrCreateService < BaseService
        def execute
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          verification_step = ::Dast::PreScanVerificationStep.find_or_create_by(check_type: step, dast_pre_scan_verification: verification) # rubocop:disable CodeReuse/ActiveRecord

          return ServiceResponse.error(message: error_message(verification_step)) unless verification_step.persisted?

          ServiceResponse.success(payload: { verification_step: verification_step })
        rescue ArgumentError
          ServiceResponse.error(message: format_error_message("#{step} is not a valid pre step name"))
        end
      end
    end
  end
end
