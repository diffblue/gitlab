# frozen_string_literal: true

module Types
  class DastSiteValidationStatusEnum < BaseEnum
    value 'PENDING_VALIDATION', value: 'pending', description: 'Site validation process has not started.'
    value 'INPROGRESS_VALIDATION', value: 'inprogress', description: 'Site validation process is in progress.'
    value 'PASSED_VALIDATION', value: 'passed', description: 'Site validation process finished successfully.'
    value 'FAILED_VALIDATION', value: 'failed', description: 'Site validation process finished but failed.'
  end
end
