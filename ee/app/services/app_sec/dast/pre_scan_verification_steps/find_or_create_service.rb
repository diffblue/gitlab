# frozen_string_literal: true

module AppSec
  module Dast
    module PreScanVerificationSteps
      class FindOrCreateService < BaseService
        def execute
          return ServiceResponse.error(message: _('Insufficient permissions')) unless allowed?

          verification_step = ::Dast::PreScanVerificationStep.find_or_create_by(name: step, dast_pre_scan_verification: verification) # rubocop:disable CodeReuse/ActiveRecord

          return ServiceResponse.error(message: error_message(verification_step)) unless verification_step.persisted?

          ServiceResponse.success(payload: { verification_step: verification_step })
        end
      end
    end
  end
end
