# frozen_string_literal: true

FactoryBot.define do
  factory :dast_pre_scan_verification_step, class: 'Dast::PreScanVerificationStep' do
    check_type { 'connection' }
    dast_pre_scan_verification
  end
end
