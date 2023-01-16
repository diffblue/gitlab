# frozen_string_literal: true

module Dast
  class PreScanVerificationStepPolicy < BasePolicy
    delegate { @subject.dast_pre_scan_verification }
  end
end
