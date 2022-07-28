# frozen_string_literal: true

module Types
  module Geo
    class VerificationStateEnum < BaseEnum
      value 'PENDING',   value: 'pending', description: 'Verification process has not started.'
      value 'STARTED',   value: 'started', description: 'Verification process is in progress.'
      value 'SUCCEEDED', value: 'succeeded', description: 'Verification process finished successfully.'
      value 'FAILED',    value: 'failed', description: 'Verification process finished but failed.'
      value 'DISABLED',  value: 'disabled', description: 'Verification process is disabled.'
    end
  end
end
