# frozen_string_literal: true

module Dast
  class PreScanVerificationStep < ApplicationRecord
    include IgnorableColumns

    self.table_name = 'dast_pre_scan_verification_steps'

    ignore_column :name, remove_with: '16.0', remove_after: '2023-05-17'

    belongs_to :dast_pre_scan_verification, class_name: 'Dast::PreScanVerification', optional: false

    enum check_type: { connection: 0, authentication: 1, crawling: 2 }, _prefix: true

    def success?
      verification_errors.blank?
    end
  end
end
