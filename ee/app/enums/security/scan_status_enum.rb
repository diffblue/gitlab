# frozen_string_literal: true

module Security
  module ScanStatusEnum
    extend DeclarativeEnum

    key :status
    name 'ScanStatus'
    description 'The status of the security scan'

    define do
      created value: 0, description: N_('The scan has been created.')
      succeeded value: 1, description: N_('The report has been successfully prepared.')
      job_failed value: 2, description: N_('The related CI build failed.')
      report_error value: 3, description: N_('The report artifact provided by the CI build couldn\'t be parsed.')
      preparing value: 4, description: N_('Preparing the report for the scan.')
      preparation_failed value: 5, description: N_('Report couldn\'t be prepared.')
      purged value: 6, description: N_('Report for the scan has been removed from the database.')
    end
  end
end
