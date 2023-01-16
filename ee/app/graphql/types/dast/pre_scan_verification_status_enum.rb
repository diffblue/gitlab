# frozen_string_literal: true

module Types
  module Dast
    class PreScanVerificationStatusEnum < BaseEnum
      graphql_name 'DastPreScanVerificationStatus'
      description 'Status of DAST pre scan verification.'

      value 'RUNNING', value: 'running', description: 'Pre Scan Verification in execution.'
      value 'COMPLETE', value: 'complete', description: 'Pre Scan Verification complete without errors.'
      value 'COMPLETE_WITH_ERRORS', value: 'complete_with_errors',
      description: 'Pre Scan Verification finished with one or more errors.'
      value 'FAILED', value: 'failed', description: 'Pre Scan Validation unable to finish.'
    end
  end
end
