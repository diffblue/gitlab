# frozen_string_literal: true

module Dast
  class PreScanVerificationStep < ApplicationRecord
    self.table_name = 'dast_pre_scan_verification_steps'

    belongs_to :dast_pre_scan_verification, class_name: 'Dast::PreScanVerification', optional: false

    def success?
      verification_errors.blank?
    end
  end
end
