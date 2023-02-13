# frozen_string_literal: true

module Dast
  class PreScanVerification < ApplicationRecord
    self.table_name = 'dast_pre_scan_verifications'

    belongs_to :ci_pipeline, class_name: 'Ci::Pipeline', optional: true
    belongs_to :dast_profile, class_name: 'Dast::Profile', optional: false, inverse_of: :dast_pre_scan_verification

    has_many :pre_scan_verification_steps, class_name: 'Dast::PreScanVerificationStep',
             foreign_key: 'dast_pre_scan_verification_id', inverse_of: :dast_pre_scan_verification

    delegate :project, :dast_site_profile, to: :dast_profile, allow_nil: true

    enum status: { running: 0, complete: 1, complete_with_errors: 2, failed: 3 }

    validates :dast_profile_id, :status, presence: true

    def verification_valid?
      created_at > dast_site_profile.updated_at
    end
  end
end
